log = Log.open_topic("s-rnnoise")

filter_nodes = {}

SimpleEventHook {
  name = "node/rnnoise/create",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "node-added" },
      Constraint { "media.class", "=", "Audio/Source" },
      -- Only match real hardware nodes; filter-chain outputs have node.virtual = "true"
      Constraint { "node.virtual", "-" },
    },
  },
  execute = function(event)
    local node      = event:get_subject()
    local node_name = node.properties["node.name"]
    local node_desc = node.properties["node.description"] or node_name

    -- Skip monitor sources (output sink monitors exposed as sources)
    if node_name:match("%.monitor$") then return end

    -- Don't create a filter for nodes we already have one for
    if filter_nodes[node.id] then return end

    log:debug("Creating rnnoise filter for " .. node_name)

    local args = string.format([[
      node.description = "Noise Canceling - %s"
      media.name       = "Noise Canceling - %s"
      filter.graph = {
        nodes = [
          {
            type   = ladspa
            name   = rnnoise
            plugin = /usr/lib/ladspa/librnnoise_ladspa.so
            label  = noise_suppressor_mono
            control = {
              "VAD Threshold (%%)"          = 40.0
              "VAD Grace Period (ms)"      = 500
              "Retroactive VAD Grace (ms)" = 0
            }
          }
        ]
      }
      capture.props = {
        node.name     = "capture.rnnoise.%s"
        node.passive  = true
        audio.rate    = 48000
        target.object = "%s"
      }
      playback.props = {
        node.name   = "rnnoise.%s"
        media.class = Audio/Source
        audio.rate  = 48000
      }
    ]], node_desc, node_desc, node_name, node_name, node_name)

    filter_nodes[node.id] = LocalModule("libpipewire-module-filter-chain", args, {})
  end
}:register()

SimpleEventHook {
  name = "node/rnnoise/free",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "node-removed" },
      Constraint { "media.class", "=", "Audio/Source" },
    },
  },
  execute = function(event)
    local node = event:get_subject()
    if filter_nodes[node.id] then
      log:debug("Freeing rnnoise filter for node " .. node.id)
      filter_nodes[node.id] = nil
    end
  end
}:register()
