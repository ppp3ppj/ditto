const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = plugin(function({matchComponents, theme}) {
  let iconsDir = path.join(__dirname, "../node_modules/remixicon/icons")
  let values = {}
  fs.readdirSync(iconsDir).forEach(category => {
    let categoryDir = path.join(iconsDir, category)
    if (fs.statSync(categoryDir).isDirectory()) {
      fs.readdirSync(categoryDir).forEach(file => {
        if (file.endsWith(".svg")) {
          let name = path.basename(file, ".svg")
          values[name] = {name, fullPath: path.join(categoryDir, file)}
        }
      })
    }
  })
  matchComponents({
    "ri": ({name, fullPath}) => {
      let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
      content = encodeURIComponent(content)
      let size = theme("spacing.6")
      return {
        [`--ri-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
        "-webkit-mask": `var(--ri-${name})`,
        "mask": `var(--ri-${name})`,
        "mask-repeat": "no-repeat",
        "mask-size": "contain",
        "mask-position": "center",
        "background-color": "currentColor",
        "vertical-align": "middle",
        "display": "inline-block",
        "width": size,
        "height": size
      }
    }
  }, {values})
})
