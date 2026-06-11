///|
fn module_name(skill_name : String) -> String {
  "username/" + skill_name
}

///|
fn target_name(dir : String) -> String {
  @path.Path(dir).normalize().basename().to_owned()
}

///|
fn path_join(base : String, child : String) -> String {
  @path.Path::join(base, child).to_string()
}

///|
fn path_exists(path : String) -> Bool raise {
  @miniio.exists(path) catch {
    @miniio.Errno::Noent => false
    err => raise err
  }
}

///|
fn ensure_dir_recursive(path : String) -> Unit raise {
  let normalized = @path.Path(path).normalize().to_string()
  if normalized == "" || normalized == "." {
    return
  }
  if path_exists(normalized) {
    guard @miniio.is_dir(normalized) else {
      raise InvalidTarget("target exists but is not a directory: " + normalized)
    }
    return
  }
  let parent = @path.Path(normalized).dirname().to_string()
  if parent != "" && parent != "." && parent != normalized {
    ensure_dir_recursive(parent)
  }
  @miniio.mkdir(normalized) catch {
    @miniio.Errno::Exist => ()
    err => raise err
  }
}

///|
fn ensure_target_dir(path : String) -> Unit raise {
  let name = target_name(path)
  if name == "" || name == "." || name == ".." {
    raise InvalidTarget("target directory must have a usable basename")
  }
  if path_exists(path) {
    guard @miniio.is_dir(path) else {
      raise InvalidTarget("target exists but is not a directory: " + path)
    }
    let entries = @miniio.readdir(path, include_hidden=true, sort=true)
    if !entries.is_empty() {
      raise NonEmptyDirectory("target directory is not empty: " + path)
    }
  } else {
    ensure_dir_recursive(path)
  }
}
