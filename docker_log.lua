require "string"

local msg_type      = read_config("type")
local kubernetes    = read_config("kubernetes")
local container_name_as_type    = read_config("container_name_as_type")
local container_id_as_hostname    = read_config("container_id_as_hostname")
local default_type    = read_config("default_type")

if container_name_as_type == nil then
    container_name_as_type = true
end

if kubernetes then
    if container_id_as_hostname == nil then
        container_id_as_hostname = true
    end
end

if default_type == nil then
    default_type = "docker"
end

local msg = {
Timestamp   = nil,
Type        = nil,
Payload     = nil,
Hostname      = nil,
Severity    = nil
}

function get_container_name(name)
    if kubernetes then
        local s = string.match(name, "^k8s_([^%.]+)%.")
        if s then
            return true, s
        else
            return false, name
        end
    else
        return false, name
    end
end

function process_message ()
    local k8s_container, container_name = get_container_name(read_message("Fields[ContainerName]"))
    local container_id = read_message("Fields[ContainerID]")
    if not msg_type then
        if container_name_as_type then
            if not k8s_container then
                msg.Type = default_type
            else
                msg.Type = container_name
            end
        else
            msg.Type = read_message("Type")
        end
    else
        msg.Type = msg_type
    end

    local fields = {
        ContainerID = read_message("Fields[ContainerID]")
    }

    msg.Payload = read_message("Payload")
    msg.Timestamp = read_message("Timestamp")
    msg.Severity = read_message("Severity")
    if container_id_as_hostname then
        msg.Hostname = container_id
    else
        msg.Hostname = container_name
    end
    msg.Fields = fields

    inject_message(msg)
    return 0
end
