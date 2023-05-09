local util = require 'lspconfig.util'
local log = require 'vim.lsp.log'

local bin_name = 'rescript-relay-compiler'
local cmd = { 'npx', bin_name, 'lsp' }

if vim.fn.has 'win32' == 1 then
  cmd = { 'cmd.exe', '/C', bin_name, 'lsp' }
end

return {
  default_config = {
    cmd = cmd,
    filetypes = {
      'rescript'
    },
    root_dir = util.root_pattern('relay.config.*', 'package.json'),
    on_new_config = function(config, root_dir)
      local project_root = util.find_node_modules_ancestor(root_dir)
      local node_bin_path = util.path.join(project_root, 'node_modules', '.bin')
      local compiler_cmd = { util.path.join(node_bin_path, bin_name), '--watch' }
      local path = node_bin_path .. util.path.path_separator .. vim.env.PATH
      if config.cmd_env then
        config.cmd_env.PATH = path
      else
        config.cmd_env = { PATH = path }
      end

      if config.path_to_config then
        config.path_to_config = util.path.sanitize(config.path_to_config)
        local path_to_config = util.path.join(root_dir, config.path_to_config)
        if util.path.exists(path_to_config) then
          vim.list_extend(config.cmd, { config.path_to_config })
          vim.list_extend(compiler_cmd, { config.path_to_config })
        else
          log.error "[Relay LSP] Can't find Relay config file. Fallback to the default location..."
        end
      end
      if config.auto_start_compiler then
        vim.fn.jobstart(compiler_cmd, {
          on_exit = function()
            log.info '[Relay LSP] Relay Compiler exited'
          end,
          cwd = project_root,
        })
      end
    end,
    handlers = {
      ['window/showStatus'] = function(_, result)
        if not result then
          return {}
        end
        local log_message = string.format('[Relay LSP] %q', result.message)
        if result.type == 1 then
          log.error(log_message)
        end
        if result.type == 2 then
          log.warn(log_message)
        end
        if result.type == 3 then
          log.info(log_message)
        end
        return {}
      end,
    },
  },
  docs = {
    description = [[https://github.com/zth/vscode-rescript-relay]],
    default_config = {
      root_dir = [[root_pattern("relay.config.*", "package.json")]],
      auto_start_compiler = false,
      path_to_config = nil,
    },
  },
}
