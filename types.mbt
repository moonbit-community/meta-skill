///|
let default_description = "Build and run a portable MoonBit WASM skill."

///|
let miniio_version = "0.2.0"

///|
priv struct TemplateFile {
  path : String
  content : String
}

///|
priv struct CheckItem {
  status : String
  message : String
}

///|
priv suberror MetaSkillError {
  InvalidTarget(String)
  NonEmptyDirectory(String)
}

///|
fn MetaSkillError::message(self : MetaSkillError) -> String {
  match self {
    InvalidTarget(message) | NonEmptyDirectory(message) => message
  }
}

///|
impl Show for MetaSkillError with fn output(self, logger) {
  logger.write_string(self.message())
}

///|
fn moon_string(value : String) -> String {
  value.escape()
}
