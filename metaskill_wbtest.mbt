///|
fn file_content(files : Array[TemplateFile], path : String) -> String? {
  for file in files {
    if file.path == path {
      return Some(file.content)
    }
  }
  None
}

///|
fn has_check_item(
  items : Array[CheckItem],
  status : String,
  message : String,
) -> Bool {
  for item in items {
    if item.status == status && item.message == message {
      return true
    }
  }
  false
}

///|
fn generated_check_items() -> Array[CheckItem] {
  let files = template_files("demo-skill", "Demo skill")
  let items : Array[CheckItem] = []
  check_skill_file_contents(
    items,
    file_content(files, "moon.mod"),
    file_content(files, "moon.pkg"),
    file_content(files, "SKILL.md"),
  )
  check_disallowed_flags(items, false, false)
  items
}

///|
fn ignore_rmdir(path : String) -> Unit {
  @miniio.rmdir(path, recursive=true) catch {
    _ => ()
  }
}

///|
fn clean_test_dir(path : String) -> Unit {
  @miniio.remove(path) catch {
    @miniio.Errno::Noent => ()
    @miniio.Errno::Notempty => ignore_rmdir(path)
    _ => ()
  }
}

///|
test "target_name uses basename" {
  assert_eq(target_name("foo"), "foo")
  assert_eq(target_name("nested/foo"), "foo")
}

///|
test "module_name uses username placeholder and basename" {
  assert_eq(module_name("demo-skill"), "username/demo-skill")
}

///|
test "template_files include expected files" {
  let files = template_files("demo-skill", "Demo skill")
  assert_true(file_content(files, "moon.mod") is Some(_))
  assert_true(file_content(files, "moon.pkg") is Some(_))
  assert_true(file_content(files, "main.mbt") is Some(_))
  assert_true(file_content(files, ".gitignore") is Some(_))
  assert_true(file_content(files, "AGENTS.md") is Some(_))
  assert_true(file_content(files, "main_test.mbt") is None)
  assert_true(file_content(files, "README.md") is Some(_))
  assert_true(file_content(files, "SKILL.md") is Some(_))
}

///|
test "template_files write moon.mod format" {
  let files = template_files("demo-skill", "Demo skill")
  guard file_content(files, "moon.mod") is Some(content) else { panic() }
  assert_true(content.contains("name = \"username/demo-skill\""))
  assert_true(content.contains("preferred_target = \"wasm\""))
  assert_true(content.contains("supported_targets = \"wasm\""))
  assert_true(content.contains("\"moonbit-community/miniio@0.2.0\""))
}

///|
test "template_files write wasm main package" {
  let files = template_files("demo-skill", "Demo skill")
  guard file_content(files, "moon.pkg") is Some(content) else { panic() }
  assert_true(content.contains("\"moonbit-community/miniio\""))
  assert_true(content.contains("\"moonbitlang/core/argparse\""))
  assert_true(content.contains("supported_targets = \"wasm\""))
  assert_true(content.contains("\"is-main\": true"))
}

///|
test "template_files write argparse cli" {
  let files = template_files("demo-skill", "Demo skill")
  guard file_content(files, "main.mbt") is Some(content) else { panic() }
  assert_true(content.contains("@argparse.Command"))
  assert_true(content.contains("@argparse.OptionArg"))
  assert_true(content.contains("long=\"name\""))
  assert_true(content.contains("short='n'"))
  assert_true(content.contains("try {"))
  assert_true(content.contains("let cli = @argparse.Command"))
  assert_true(content.contains("let matches = cli.parse()"))
  assert_true(content.contains("matches.values[\"name\"][0]"))
  assert_true(content.contains("println(err.to_string())"))
  assert_true(content.contains("@miniio.exit(2)"))
  assert_true(
    content.contains("@miniio.stdout.write_text(\"Hello, \\{name}!\\n\")"),
  )
  assert_eq(content.contains("@miniio.args_get"), false)
  assert_eq(content.contains("let argv"), false)
  assert_eq(content.contains("argv.push"), false)
  assert_eq(content.contains("argv=argv"), false)
  assert_eq(content.contains(".parse() catch"), false)
  assert_eq(content.contains("let default_name"), false)
  assert_eq(content.contains("pub fn greeting"), false)
  assert_eq(content.contains("pub fn command"), false)
  assert_eq(content.contains("fn command"), false)
  assert_eq(content.contains("argv_without_program"), false)
  assert_eq(content.contains("first_value"), false)
  assert_eq(content.contains("parse_cli"), false)
  assert_eq(content.contains("message_from_matches"), false)
  assert_eq(content.contains("message_from_args"), false)
  assert_eq(content.contains("write_stdout"), false)
  assert_eq(content.contains("fn die"), false)
}

///|
test "template_files write gitignore" {
  let files = template_files("demo-skill", "Demo skill")
  guard file_content(files, ".gitignore") is Some(content) else { panic() }
  inspect(
    content,
    content=(
      #|.DS_Store
      #|_build/
      #|target/
      #|target
      #|.mooncakes/
      #|.moonagent/
      #|_tmp_*
      #|
    ),
  )
}

///|
test "template_files write agents guide" {
  let files = template_files("demo-skill", "Demo skill")
  guard file_content(files, "AGENTS.md") is Some(content) else { panic() }
  inspect(
    content,
    content=(
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
    ),
  )
}

///|
test "template_files write skill frontmatter" {
  let files = template_files("demo-skill", "Demo skill")
  guard file_content(files, "SKILL.md") is Some(content) else { panic() }
  assert_true(content.contains("---\nname: demo-skill\n"))
  assert_true(content.contains("description: \"Demo skill\""))
  assert_true(content.contains("## Run"))
  assert_true(content.contains("moon runwasm username/demo-skill --name Agent"))
  assert_eq(content.contains("moon runwasm ."), false)
  assert_eq(content.contains("local"), false)
  assert_eq(content.contains("publish"), false)
  assert_true(content.contains("## Behavior"))
  assert_true(content.contains("Hello, MoonBit!"))
  assert_true(content.contains("--name <value>"))
  assert_eq(content.contains("main.mbt"), false)
  assert_eq(content.contains("moon.pkg"), false)
  assert_eq(content.contains("moon check"), false)
  assert_eq(content.contains("moon test"), false)
  assert_eq(content.contains("moon build"), false)
  assert_eq(content.contains("## MiniIO Guidance"), false)
  assert_eq(content.contains("wasmtime run --dir ./data::data"), false)
}

///|
test "create_wasm_skill writes minimal project" {
  let dir = "_tmp_meta_skill_create"
  clean_test_dir(dir)
  defer clean_test_dir(dir)
  try! create_wasm_skill(dir, "Generated demo")
  assert_eq(@miniio.exists(path_join(dir, "moon.mod")), true)
  assert_eq(@miniio.exists(path_join(dir, "moon.pkg")), true)
  assert_eq(@miniio.exists(path_join(dir, "main.mbt")), true)
  assert_eq(@miniio.exists(path_join(dir, ".gitignore")), true)
  assert_eq(@miniio.exists(path_join(dir, "AGENTS.md")), true)
  assert_eq(@miniio.exists(path_join(dir, "main_test.mbt")), false)
  assert_eq(@miniio.exists(path_join(dir, "README.md")), true)
  assert_eq(@miniio.exists(path_join(dir, "SKILL.md")), true)
}

///|
test "create_wasm_skill rejects non-empty directory" {
  let dir = "_tmp_meta_skill_nonempty"
  clean_test_dir(dir)
  defer clean_test_dir(dir)
  @miniio.mkdir(dir)
  @miniio.write_text_file(path_join(dir, "existing.txt"), "exists")
  try create_wasm_skill(dir, "Generated demo") catch {
    err =>
      inspect(
        err.to_string(),
        content=(
          #|target directory is not empty: _tmp_meta_skill_nonempty
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "post_create_message tells agent follow-up commands" {
  let message = post_create_message("skill1", "skill1")
  assert_true(message.contains("moon whoami"))
  assert_true(message.contains("skill1/moon.mod"))
  assert_true(message.contains("name = \"<username>/skill1\""))
  assert_true(message.contains("moon add -u moonbit-community/miniio"))
  assert_eq(message.contains("@latest"), false)
}

///|
test "check generated template has warnings but no failures" {
  let items = generated_check_items()
  assert_eq(has_check_status(items, "fail"), false)
  assert_eq(has_check_status(items, "warn"), true)
  assert_true(
    has_check_item(items, "warn", "moon.mod still uses username placeholder"),
  )
  assert_true(
    render_check_report(items).contains("Status: passed with warnings"),
  )
  assert_true(
    render_check_report(items).contains(
      "Warnings:\n  - moon.mod still uses username placeholder",
    ),
  )
}

///|
test "check does not validate miniio version" {
  let items : Array[CheckItem] = []
  check_skill_file_contents(
    items,
    Some(
      moon_mod_content("user/demo-skill", "Demo skill").replace_all(
        old="miniio@0.2.0",
        new="miniio@9.9.9",
      ),
    ),
    Some(moon_pkg_content()),
    Some(skill_md_content("demo-skill", "user/demo-skill", "Demo skill")),
  )
  check_disallowed_flags(items, false, false)
  assert_eq(has_check_status(items, "fail"), false)
  assert_true(has_check_item(items, "pass", "moon.mod depends on miniio"))
}

///|
test "check reports missing wasm target" {
  let items : Array[CheckItem] = []
  check_skill_file_contents(
    items,
    Some(
      moon_mod_content("user/demo-skill", "Demo skill").replace_all(
        old="supported_targets = \"wasm\"",
        new="",
      ),
    ),
    Some(moon_pkg_content()),
    Some(skill_md_content("demo-skill", "user/demo-skill", "Demo skill")),
  )
  assert_true(
    has_check_item(
      items, "fail", "moon.mod missing supported_targets = \"wasm\"",
    ),
  )
}

///|
test "check reports missing miniio without checking version" {
  let items : Array[CheckItem] = []
  check_skill_file_contents(
    items,
    Some(
      moon_mod_content("user/demo-skill", "Demo skill").replace_all(
        old="moonbit-community/miniio",
        new="other/pkg",
      ),
    ),
    Some(
      moon_pkg_content().replace_all(
        old="moonbit-community/miniio",
        new="other/pkg",
      ),
    ),
    Some(skill_md_content("demo-skill", "user/demo-skill", "Demo skill")),
  )
  assert_true(
    has_check_item(
      items, "fail", "moon.mod missing moonbit-community/miniio dependency",
    ),
  )
  assert_true(
    has_check_item(
      items, "fail", "moon.pkg missing moonbit-community/miniio import",
    ),
  )
}

///|
test "check reports disallowed packages" {
  let items : Array[CheckItem] = []
  check_disallowed_flags(items, true, true)
  assert_true(has_check_item(items, "fail", "uses moonbitlang/async"))
  assert_true(has_check_item(items, "fail", "uses moonbitlang/x/fs"))
}

///|
test "dependency scan ignores diagnostic strings" {
  assert_eq(
    has_dependency_line(
      "results.push(\"uses moonbitlang/x/fs\")", "moonbitlang/x/fs",
    ),
    false,
  )
  assert_eq(
    has_dependency_line("  \"moonbitlang/x/fs\",", "moonbitlang/x/fs"),
    true,
  )
}

///|
test "check reports missing skill frontmatter fields" {
  let items : Array[CheckItem] = []
  check_skill_file_contents(
    items,
    Some(moon_mod_content("user/demo-skill", "Demo skill")),
    Some(moon_pkg_content()),
    Some(
      skill_md_content("demo-skill", "user/demo-skill", "Demo skill").replace_all(
        old="name: demo-skill\ndescription: \"Demo skill\"",
        new="title: demo-skill",
      ),
    ),
  )
  assert_true(
    has_check_item(items, "fail", "SKILL.md frontmatter missing name"),
  )
  assert_true(
    has_check_item(items, "fail", "SKILL.md frontmatter missing description"),
  )
}

///|
test "check command defaults dir to current directory" {
  let cli = @argparse.Command("meta-skill", subcommand_required=true, subcommands=[
    @argparse.Command("check", positionals=[
      @argparse.PositionArg(
        "dir",
        default_values=["."],
        num_args=@argparse.ValueRange(lower=0, upper=1),
      ),
    ]),
  ])
  let matches = try! cli.parse(argv=["check"], env={})
  guard matches.subcommand is Some(("check", child)) else { panic() }
  assert_eq(child.values["dir"][0], ".")
  let explicit = try! cli.parse(argv=["check", "skill1"], env={})
  guard explicit.subcommand is Some(("check", child)) else { panic() }
  assert_eq(child.values["dir"][0], "skill1")
}

///|
test "check_wasm_skill succeeds on generated project" {
  let dir = "_tmp_meta_skill_check_ok"
  clean_test_dir(dir)
  defer clean_test_dir(dir)
  try! create_wasm_skill(dir, "Generated demo")
  let items = try! check_wasm_skill(dir)
  assert_eq(has_check_status(items, "fail"), false)
  assert_true(has_check_item(items, "pass", "target is a directory"))
  assert_true(has_check_item(items, "pass", "module has a single main package"))
  assert_true(
    render_check_report(items).contains("Status: passed with warnings"),
  )
}

///|
test "check_wasm_skill warns on multiple main packages" {
  let dir = "_tmp_meta_skill_multi_main"
  clean_test_dir(dir)
  defer clean_test_dir(dir)
  try! create_wasm_skill(dir, "Generated demo")
  try! ensure_dir_recursive(path_join(dir, "cmd"))
  @miniio.write_text_file(path_join(dir, "cmd/moon.pkg"), moon_pkg_content())
  let items = try! check_wasm_skill(dir)
  assert_true(has_check_status(items, "warn"))
  assert_true(
    render_check_report(items).contains("module has multiple main packages"),
  )
  assert_true(
    render_check_report(items).contains("prefer only the root package as main"),
  )
}

///|
test "check_wasm_skill skips main packages in nested modules" {
  let dir = "_tmp_meta_skill_nested_module"
  clean_test_dir(dir)
  defer clean_test_dir(dir)
  try! create_wasm_skill(dir, "Generated demo")
  let nested = path_join(dir, "nested")
  try! ensure_dir_recursive(nested)
  @miniio.write_text_file(
    path_join(nested, "moon.mod"),
    moon_mod_content("user/nested", "Nested demo"),
  )
  @miniio.write_text_file(path_join(nested, "moon.pkg"), moon_pkg_content())
  let items = try! check_wasm_skill(dir)
  assert_true(has_check_item(items, "pass", "module has a single main package"))
  assert_eq(
    render_check_report(items).contains("module has multiple main packages"),
    false,
  )
}

///|
test "check_wasm_skill fails when required file is missing" {
  let dir = "_tmp_meta_skill_check_missing"
  clean_test_dir(dir)
  defer clean_test_dir(dir)
  try! create_wasm_skill(dir, "Generated demo")
  @miniio.remove_file(path_join(dir, "SKILL.md"))
  let items = try! check_wasm_skill(dir)
  assert_true(has_check_item(items, "fail", "missing SKILL.md"))
  assert_true(render_check_report(items).contains("Status: failed"))
  assert_true(
    render_check_report(items).contains("Failures:\n  - missing SKILL.md"),
  )
}

///|
test "check_wasm_skill fails when target is a file" {
  let path = "_tmp_meta_skill_check_file"
  clean_test_dir(path)
  defer clean_test_dir(path)
  @miniio.write_text_file(path, "not a directory")
  let items = try! check_wasm_skill(path)
  assert_true(
    has_check_item(
      items, "fail", "target is not a directory: _tmp_meta_skill_check_file",
    ),
  )
}
