-- Stub editor APIs: no plugin startup, network, external commands or real writes.
local source = assert(arg[1])
for _, account in ipairs({ { home = "/home/john", uid = 1000 }, { home = "/root", uid = 0 } }) do
  local files, writes, autocmds = {}, {}, {}
  local dirs = {
    config = account.home .. "/.config/nvim",
    state = account.home .. "/.local/state/nvim",
    data = account.home .. "/.local/share/nvim",
    cache = account.home .. "/.cache/nvim",
  }
  files[dirs.config .. "/lazy-lock.json"] = { "seed" }
  vim = {
    env = { HOME = account.home },
    fn = {
      stdpath = function(kind) return assert(dirs[kind]) end,
      mkdir = function(path) assert(path == dirs.state) end,
      filereadable = function(path) return files[path] and 1 or 0 end,
      readfile = function(path) return assert(files[path]) end,
      writefile = function(contents, path) files[path] = contents; writes[#writes + 1] = path end,
      getuid = function() return account.uid end,
      getcwd = function() return account.home .. "/project" end,
      fnamemodify = function() return "project" end,
      glob = function(path) return path end,
    },
    api = {
      nvim_create_augroup = function() return 1 end,
      nvim_create_autocmd = function(event, opts) autocmds[#autocmds + 1] = { event, opts } end,
    },
  }
  local shared = assert(loadfile(source .. "/lua/installdoc_shared.lua"))()
  assert(shared.lazy_options().lockfile == dirs.state .. "/lazy-lock.json")
  assert(#writes == 1 and writes[1] == dirs.state .. "/lazy-lock.json")
  files[writes[1]] = { "existing account lock" }
  shared.lazy_options()
  assert(#writes == 1, "existing account lockfile must be preserved")

  local captured
  package.loaded.jdtls = { start_or_attach = function(config) captured = config end }
  assert(loadfile(source .. "/lua/giga/lsp/jdtls_setup.lua"))():setup()
  assert(captured.cmd[#captured.cmd] == dirs.cache .. "/jdtls/workspace/project")
  assert(captured.init_options.bundles[1]:sub(1, #dirs.data) == dirs.data)
  if account.uid == 0 then
    for _, command in ipairs(captured.cmd) do
      assert(not command:find("/home/john", 1, true), "root Java config references user runtime")
    end
  end
  assert(loadfile(source .. "/lua/giga/autocmd.lua"))()
  local uploads = 0
  for _, autocmd in ipairs(autocmds) do
    if autocmd[1] == "BufWritePost" then uploads = uploads + 1 end
  end
  assert(uploads == (account.uid == 0 and 0 or 1))
end
