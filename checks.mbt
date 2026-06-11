///|
fn check_item(status : String, message : String) -> CheckItem {
  { status, message }
}

///|
fn has_check_status(items : Array[CheckItem], status : String) -> Bool {
  for item in items {
    if item.status == status {
      return true
    }
  }
  false
}

///|
fn render_check_report(items : Array[CheckItem]) -> String {
  let passed : Array[String] = []
  let warnings : Array[String] = []
  let failures : Array[String] = []
  for item in items {
    match item.status {
      "pass" => passed.push(item.message)
      "warn" => warnings.push(item.message)
      "fail" => failures.push(item.message)
      _ => ()
    }
  }
  let status = if !failures.is_empty() {
    "failed"
  } else if !warnings.is_empty() {
    "passed with warnings"
  } else {
    "passed"
  }
  let lines : Array[String] = []
  lines.push("Status: " + status)
  lines.push("")
  lines.push("Summary:")
  lines.push("  passed: " + passed.length().to_string())
  lines.push("  warnings: " + warnings.length().to_string())
  lines.push("  failures: " + failures.length().to_string())
  if !failures.is_empty() {
    lines.push("")
    lines.push("Failures:")
    for message in failures {
      lines.push("  - " + message)
    }
  }
  if !warnings.is_empty() {
    lines.push("")
    lines.push("Warnings:")
    for message in warnings {
      lines.push("  - " + message)
    }
  }
  if !passed.is_empty() {
    lines.push("")
    lines.push("Passed:")
    for message in passed {
      lines.push("  - " + message)
    }
  }
  lines.join("\n") + "\n"
}

///|
fn read_required_file(
  results : Array[CheckItem],
  dir : String,
  file : String,
) -> String? raise {
  let file_path = path_join(dir, file)
  if !path_exists(file_path) {
    results.push(check_item("fail", "missing " + file))
    return None
  }
  if @miniio.is_dir(file_path) {
    results.push(check_item("fail", file + " is a directory"))
    return None
  }
  results.push(check_item("pass", file + " exists"))
  Some(@miniio.read_text_file(file_path))
}

///|
fn check_contains(
  results : Array[CheckItem],
  content : String,
  needle : String,
  pass_message : String,
  fail_message : String,
) -> Unit {
  if content.contains(needle) {
    results.push(check_item("pass", pass_message))
  } else {
    results.push(check_item("fail", fail_message))
  }
}

///|
fn has_frontmatter_field(content : String, field : String) -> Bool {
  if !content.has_prefix("---\n") {
    return false
  }
  let prefix = field + ":"
  let mut first = true
  for line in content.split("\n") {
    if first {
      first = false
    } else if line.trim() == "---" {
      return false
    } else if line.trim_start().has_prefix(prefix) {
      return true
    }
  }
  false
}

///|
fn check_frontmatter_field(
  results : Array[CheckItem],
  content : String,
  field : String,
) -> Unit {
  if has_frontmatter_field(content, field) {
    results.push(check_item("pass", "SKILL.md frontmatter has " + field))
  } else {
    results.push(check_item("fail", "SKILL.md frontmatter missing " + field))
  }
}

///|
fn check_skill_file_contents(
  results : Array[CheckItem],
  moon_mod : String?,
  moon_pkg : String?,
  skill_md : String?,
) -> Unit {
  match moon_mod {
    Some(content) => {
      check_contains(
        results, content, "supported_targets = \"wasm\"", "moon.mod configures wasm target",
        "moon.mod missing supported_targets = \"wasm\"",
      )
      check_contains(
        results, content, "moonbit-community/miniio", "moon.mod depends on miniio",
        "moon.mod missing moonbit-community/miniio dependency",
      )
      if content.contains("name = \"username/") {
        results.push(
          check_item("warn", "moon.mod still uses username placeholder"),
        )
      } else {
        results.push(
          check_item("pass", "moon.mod module name is not username placeholder"),
        )
      }
    }
    None => ()
  }
  match moon_pkg {
    Some(content) => {
      check_contains(
        results, content, "supported_targets = \"wasm\"", "moon.pkg configures wasm target",
        "moon.pkg missing supported_targets = \"wasm\"",
      )
      check_contains(
        results, content, "\"is-main\": true", "moon.pkg configures main package",
        "moon.pkg missing options(\"is-main\": true)",
      )
      check_contains(
        results, content, "moonbit-community/miniio", "moon.pkg imports miniio",
        "moon.pkg missing moonbit-community/miniio import",
      )
    }
    None => ()
  }
  match skill_md {
    Some(content) => {
      check_frontmatter_field(results, content, "name")
      check_frontmatter_field(results, content, "description")
    }
    None => ()
  }
}

///|
fn should_skip_scan_dir(name : String) -> Bool {
  name == ".git" || name == ".mooncakes" || name == "_build"
}

///|
fn should_scan_text_file(path : String) -> Bool {
  let name = @path.Path(path).basename().to_owned()
  name == "moon.mod" ||
  name == "moon.pkg" ||
  path.strip_suffix(".mbt") is Some(_) ||
  path.strip_suffix(".mbti") is Some(_) ||
  path.strip_suffix(".mbt.md") is Some(_)
}

///|
fn has_dependency_line(content : String, dependency : String) -> Bool {
  let quoted = "\"" + dependency
  for line in content.split("\n") {
    if line.trim_start().has_prefix(quoted) {
      return true
    }
  }
  false
}

///|
fn scan_is_dir(path : String) -> Bool raise {
  @miniio.is_dir(path) catch {
    @miniio.Errno::Loop => false
    err => raise err
  }
}

///|
fn scan_project_text(dir : String) -> (Bool, Bool) raise {
  let mut found_async = false
  let mut found_x_fs = false
  for name in @miniio.readdir(dir, include_hidden=true, sort=true) {
    if !should_skip_scan_dir(name) {
      let child = path_join(dir, name)
      if scan_is_dir(child) {
        let (child_async, child_x_fs) = scan_project_text(child)
        if child_async {
          found_async = true
        }
        if child_x_fs {
          found_x_fs = true
        }
      } else if should_scan_text_file(child) {
        let content = @miniio.read_text_file(child)
        if has_dependency_line(content, "moonbitlang/async") {
          found_async = true
        }
        if has_dependency_line(content, "moonbitlang/x/fs") {
          found_x_fs = true
        }
      }
    }
  }
  (found_async, found_x_fs)
}

///|
fn check_disallowed_usage(
  results : Array[CheckItem],
  dir : String,
) -> Unit raise {
  let (found_async, found_x_fs) = scan_project_text(dir)
  check_disallowed_flags(results, found_async, found_x_fs)
}

///|
fn check_disallowed_flags(
  results : Array[CheckItem],
  found_async : Bool,
  found_x_fs : Bool,
) -> Unit {
  if found_async {
    results.push(check_item("fail", "uses moonbitlang/async"))
  } else {
    results.push(check_item("pass", "does not use moonbitlang/async"))
  }
  if found_x_fs {
    results.push(check_item("fail", "uses moonbitlang/x/fs"))
  } else {
    results.push(check_item("pass", "does not use moonbitlang/x/fs"))
  }
}

///|
fn is_main_package_content(content : String) -> Bool {
  content.contains("\"is-main\": true")
}

///|
fn main_package_label(base : String, moon_pkg_path : String) -> String {
  let dir = @path.Path(moon_pkg_path).dirname().to_string()
  if dir == base {
    "."
  } else {
    @path.Path(dir).relative(base=@path.Path(base)).to_string()
  }
}

///|
fn is_nested_module_root(base : String, dir : String) -> Bool raise {
  if dir == base {
    false
  } else {
    let moon_mod = path_join(dir, "moon.mod")
    path_exists(moon_mod) && !scan_is_dir(moon_mod)
  }
}

///|
fn collect_main_packages(
  base : String,
  dir : String,
  found : Array[String],
) -> Unit raise {
  if is_nested_module_root(base, dir) {
    return
  }
  let root_pkg = path_join(dir, "moon.pkg")
  if path_exists(root_pkg) && !scan_is_dir(root_pkg) {
    let content = @miniio.read_text_file(root_pkg)
    if is_main_package_content(content) {
      found.push(main_package_label(base, root_pkg))
    }
  }
  for name in @miniio.readdir(dir, include_hidden=true, sort=true) {
    if name != "moon.pkg" && !should_skip_scan_dir(name) {
      let child = path_join(dir, name)
      if scan_is_dir(child) {
        collect_main_packages(base, child, found)
      } else if name == "moon.pkg" {
        let content = @miniio.read_text_file(child)
        if is_main_package_content(content) {
          found.push(main_package_label(base, child))
        }
      }
    }
  }
}

///|
fn check_main_package_count(
  results : Array[CheckItem],
  dir : String,
) -> Unit raise {
  let packages : Array[String] = []
  collect_main_packages(dir, dir, packages)
  if packages.length() > 1 {
    results.push(
      check_item(
        "warn",
        "module has multiple main packages (" +
        packages.join(", ") +
        "); prefer only the root package as main",
      ),
    )
  } else {
    results.push(check_item("pass", "module has a single main package"))
  }
}

///|
fn check_wasm_skill(dir : String) -> Array[CheckItem] raise {
  let results : Array[CheckItem] = []
  if !path_exists(dir) {
    results.push(check_item("fail", "target does not exist: " + dir))
    return results
  }
  if !@miniio.is_dir(dir) {
    results.push(check_item("fail", "target is not a directory: " + dir))
    return results
  }
  results.push(check_item("pass", "target is a directory"))
  let moon_mod = read_required_file(results, dir, "moon.mod")
  let moon_pkg = read_required_file(results, dir, "moon.pkg")
  let skill_md = read_required_file(results, dir, "SKILL.md")
  check_skill_file_contents(results, moon_mod, moon_pkg, skill_md)
  check_disallowed_usage(results, dir)
  check_main_package_count(results, dir)
  results
}
