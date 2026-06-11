///|
fn first_value(matches : @argparse.Matches, name : String) -> String {
  matches.values[name][0]
}

///|
fn write_stdout(text : String) -> Unit {
  @miniio.stdout.write_text(text) catch {
    err => die("stdout failed: " + err.to_string())
  }
}

///|
fn[A] die(message : String) -> A {
  @miniio.stderr.write_text("error: " + message + "\n") catch {
    _ => ()
  }
  @miniio.exit(1)
  panic()
}

///|
fn run(matches : @argparse.Matches) -> Unit raise {
  match matches.subcommand {
    Some(("new", child)) => {
      let dir = first_value(child, "dir")
      let description = first_value(child, "description")
      create_wasm_skill(dir, description)
      write_stdout(post_create_message(dir, target_name(dir)))
    }
    Some(("check", child)) => {
      let dir = first_value(child, "dir")
      let items = check_wasm_skill(dir)
      write_stdout(render_check_report(items))
      if has_check_status(items, "fail") {
        @miniio.exit(1)
      }
    }
    _ => ()
  }
}

///|
fn main {
  let matches = @argparse.Command(
    "meta-skill",
    about="Create minimal MoonBit WASM skill templates.",
    subcommand_required=true,
    subcommands=[
      @argparse.Command(
        "new",
        about="Create a minimal runnable WASM skill template.",
        options=[
          @argparse.OptionArg(
            "description",
            short='d',
            about="Skill description for generated SKILL.md and moon.mod.",
            default_values=[default_description],
          ),
        ],
        positionals=[
          @argparse.PositionArg(
            "dir",
            about="Directory to create.",
            num_args=@argparse.ValueRange::single(),
          ),
        ],
      ),
      @argparse.Command(
        "check",
        about="Inspect a MoonBit WASM skill directory.",
        positionals=[
          @argparse.PositionArg(
            "dir",
            about="Directory to inspect.",
            default_values=["."],
            num_args=@argparse.ValueRange(lower=0, upper=1),
          ),
        ],
      ),
    ],
  ).parse() catch {
    err => die(err.to_string())
  }
  run(matches) catch {
    err => die(err.to_string())
  }
}
