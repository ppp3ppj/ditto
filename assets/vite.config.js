import { defineConfig } from "vite"
import tailwindcss from "@tailwindcss/vite"
import autoprefixer from "autoprefixer"
import path from "path"

export default defineConfig(({ mode }) => ({
  plugins: [tailwindcss(), resumeStdinPlugin()],
  css: {
    postcss: {
      plugins: [autoprefixer()]
    }
  },
  publicDir: false,
  build: {
    target: "es2022",
    outDir: "../priv/static/assets",
    emptyOutDir: false,
    sourcemap: mode !== "production",
    rollupOptions: {
      input: "js/app.js",
      output: {
        entryFileNames: "js/[name].js",
        chunkFileNames: "js/[name].js",
        assetFileNames: ({name}) =>
          name?.endsWith(".css") ? "css/[name][extname]" : "[name][extname]"
      }
    }
  },
  resolve: {
    alias: {
      "phoenix": path.resolve("../deps/phoenix"),
      "phoenix_html": path.resolve("../deps/phoenix_html"),
      "phoenix_live_view": path.resolve("../deps/phoenix_live_view"),
      "phoenix-colocated/ditto": path.resolve(
        `../_build/${mode === "production" ? "prod" : "dev"}/phoenix-colocated/ditto/index.js`
      )
    }
  }
}))

// Workaround to avoid a zombie process when the watcher is started as a
// child process from Elixir. See https://github.com/vitejs/vite/issues/19091.
function resumeStdinPlugin() {
  return {
    name: "resume-stdin",
    buildStart() {
      if (process.env.WATCH_STDIN === "1") {
        process.stdin.resume()
        process.stdin.once("end", () => process.exit(0))
      }
    }
  }
}
