return {
  {
    "vyfor/cord.nvim",
    build = ":Cord update",
    opts = {
      buttons = {
        {
          label = function(opts)
            return opts.repo_url and 'View Repository' or 'My Website'
          end,
          url = function(opts)
            return opts.repo_url or 'https://example.com'
          end,
        },
      },
    },
  },
}

