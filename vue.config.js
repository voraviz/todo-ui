const { defineConfig } = require('@vue/cli-service')
// module.exports = defineConfig({
//   transpileDependencies: true
// })
    module.exports = {
      transpileDependencies: true,
      devServer: {
        hot: false, // Disables HMR
        liveReload: false, // Disables live reloading
        client: {
          overlay: false, // Disables the full-screen overlay for errors/warnings
        },
      },
    };