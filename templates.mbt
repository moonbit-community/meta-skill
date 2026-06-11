///|
fn moon_mod_content(name : String, description : String) -> String {
  let content =
    #|name = __NAME__
    #|
    #|version = "0.1.0"
    #|
    #|readme = "README.md"
    #|
    #|repository = ""
    #|
    #|license = "Apache-2.0"
    #|
    #|keywords = ["wasm", "skill", "agent"]
    #|
    #|description = __DESCRIPTION__
    #|
    #|preferred_target = "wasm"
    #|
    #|supported_targets = "wasm"
    #|
    #|import {
    #|  "moonbit-community/miniio@__MINIIO_VERSION__",
    #|}
  content
  .replace_all(old="__NAME__", new=moon_string(name))
  .replace_all(old="__DESCRIPTION__", new=moon_string(description))
  .replace_all(old="__MINIIO_VERSION__", new=miniio_version)
}

///|
fn moon_pkg_content() -> String {
  (
    #|import {
    #|  "moonbit-community/miniio",
    #|  "moonbitlang/core/argparse",
    #|}
    #|
    #|supported_targets = "wasm"
    #|
    #|options(
    #|  "is-main": true,
    #|)
  )
}

///|
fn main_mbt_content(name : String) -> String {
  let content =
    #|///|
    #|fn main {
    #|  try {
    #|    let cli = @argparse.Command(__COMMAND_NAME__, about="Print a greeting.", options=[
    #|      @argparse.OptionArg(
    #|        "name",
    #|        short='n',
    #|        long="name",
    #|        about="Name to greet.",
    #|        default_values=["MoonBit"],
    #|      ),
    #|    ])
    #|    let matches = cli.parse()
    #|    let name = matches.values["name"][0]
    #|    @miniio.stdout.write_text("__GREETING__")
    #|  } catch {
    #|    err => {
    #|      println(err.to_string())
    #|      @miniio.exit(2)
    #|    }
    #|  }
    #|}
  content
  .replace_all(old="__COMMAND_NAME__", new=moon_string(name))
  .replace_all(old="__GREETING__", new="Hello, \\{name}!\\n")
}

///|
fn gitignore_content() -> String {
  (
    #|.DS_Store
    #|_build/
    #|target/
    #|target
    #|.mooncakes/
    #|.moonagent/
    #|_tmp_*
    #|
  )
}

///|
fn agents_md_content() -> String {
  (
    #|# Project Agents.md Guide
    #|
    #|This is a [MoonBit](https://docs.moonbitlang.com) project.
    #|
    #|You can browse and install extra skills here:
    #|<https://github.com/moonbitlang/skills>
    #|
    #|## Project Structure
    #|
    #|- MoonBit packages are organized per directory; each directory contains a
    #|  `moon.pkg` file listing its dependencies. Each package has its files and
    #|  blackbox test files (ending in `_test.mbt`) and whitebox test files (ending in
    #|  `_wbtest.mbt`).
    #|
    #|- In the toplevel directory, there is a `moon.mod` file listing module
    #|  metadata.
    #|
    #|## Coding convention
    #|
    #|- MoonBit code is organized in block style, each block is separated by `///|`,
    #|  the order of each block is irrelevant. In some refactorings, you can process
    #|  block by block independently.
    #|
    #|- Try to keep deprecated blocks in file called `deprecated.mbt` in each
    #|  directory.
    #|
    #|## Tooling
    #|
    #|- `moon fmt` is used to format your code properly.
    #|
    #|- `moon ide` provides project navigation helpers like `peek-def`, `outline`, and
    #|  `find-references`. See $moonbit-agent-guide for details.
    #|
    #|- `moon info` is used to update the generated interface of the package, each
    #|  package has a generated interface file `.mbti`, it is a brief formal
    #|  description of the package. If nothing in `.mbti` changes, this means your
    #|  change does not bring the visible changes to the external package users, it is
    #|  typically a safe refactoring.
    #|
    #|- In the last step, run `moon info && moon fmt` to update the interface and
    #|  format the code. Check the diffs of `.mbti` file to see if the changes are
    #|  expected.
    #|
    #|- Run `moon test` to check tests pass. MoonBit supports snapshot testing; when
    #|  changes affect outputs, run `moon test --update` to refresh snapshots.
    #|
    #|- Prefer `assert_eq` or `assert_true(pattern is Pattern(...))` for results that
    #|  are stable or very unlikely to change. For snapshot tests that record
    #|  structured debugging output, derive `Debug` and use `debug_inspect`, rather
    #|  than deriving `Show` for debugging. For solid, well-defined results (e.g.
    #|  scientific computations), prefer assertion tests. You can use
    #|  `moon coverage analyze > uncovered.log` to see which parts of your code are
    #|  not covered by tests.
    #|
  )
}

///|
fn readme_content(name : String, module_full_name : String) -> String {
  let content =
    #|# __NAME__
    #|
    #|Portable MoonBit WASM skill created by `meta-skill`.
    #|
    #|```sh
    #|moon runwasm __MODULE__
    #|moon runwasm __MODULE__ --name Agent
    #|```
  content
  .replace_all(old="__NAME__", new=name)
  .replace_all(old="__MODULE__", new=module_full_name)
}

///|
fn skill_md_content(
  name : String,
  module_full_name : String,
  description : String,
) -> String {
  let content =
    #|---
    #|name: __NAME__
    #|description: __DESCRIPTION__
    #|---
    #|
    #|# __NAME__
    #|
    #|Use this skill when the user asks to run this MoonBit WASM CLI or understand its command-line behavior.
    #|
    #|## Run
    #|
    #|```sh
    #|moon runwasm __MODULE__
    #|moon runwasm __MODULE__ --name Agent
    #|```
    #|
    #|## Behavior
    #|
    #|- With no options, the CLI prints `Hello, MoonBit!`.
    #|- `--name <value>` or `-n <value>` changes the name in the greeting.
    #|- Argument and fatal I/O errors are written to stderr and exit nonzero.
  content
  .replace_all(old="__NAME__", new=name)
  .replace_all(old="__MODULE__", new=module_full_name)
  .replace_all(old="__DESCRIPTION__", new=moon_string(description))
}

///|
fn template_files(name : String, description : String) -> Array[TemplateFile] {
  let module_full_name = module_name(name)
  [
    {
      path: "moon.mod",
      content: moon_mod_content(module_full_name, description),
    },
    { path: "moon.pkg", content: moon_pkg_content() },
    { path: "main.mbt", content: main_mbt_content(name) },
    { path: ".gitignore", content: gitignore_content() },
    { path: "AGENTS.md", content: agents_md_content() },
    { path: "README.md", content: readme_content(name, module_full_name) },
    {
      path: "SKILL.md",
      content: skill_md_content(name, module_full_name, description),
    },
  ]
}

///|
fn create_wasm_skill(dir : String, description : String) -> Unit raise {
  ensure_target_dir(dir)
  let name = target_name(dir)
  for file in template_files(name, description) {
    @miniio.write_text_file(
      path_join(dir, file.path),
      file.content,
      create_mode=@miniio.CreateMode::CreateNew,
    )
  }
}

///|
fn post_create_message(dir : String, name : String) -> String {
  let mod_path = path_join(dir, "moon.mod")
  let content =
    #|created __DIR__
    #|
    #|Next steps for the AI agent:
    #|1. Run `moon whoami` to get the current MoonBit username, then replace `username` in `__MOD_PATH__` so the module name becomes `name = "<username>/__NAME__"`.
    #|2. Run `cd __DIR__ && moon add -u moonbit-community/miniio` to refresh the MiniIO dependency.
  content
  .replace_all(old="__DIR__", new=dir)
  .replace_all(old="__MOD_PATH__", new=mod_path)
  .replace_all(old="__NAME__", new=name) +
  "\n"
}
