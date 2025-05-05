return {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    keys = {
        {
            "-",
            mode = { "n", "v" },
            "<cmd>Yazi<cr>",
            desc = "Open yazi at the current file",
        },
    },
    opts = {
        open_for_directories = true,
        keymaps = {
            show_help = "<f1>",
        },
    },
}
