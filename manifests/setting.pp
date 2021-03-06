# Defining apt settings
define apt::setting (
  Variant[String, Integer, Array] $priority           = 50,
  Optional[Enum['file', 'present', 'absent']] $ensure = file,
  Optional[String] $source                            = undef,
  Optional[String] $content                           = undef,
  Boolean $notify_update                              = true,
) {

  if $content and $source {
    fail('apt::setting cannot have both content and source')
  }

  if !$content and !$source {
    fail('apt::setting needs either of content or source')
  }

  $title_array = split($title, '-')
  $setting_type = $title_array[0]
  $base_name = join(delete_at($title_array, 0), '-')

  assert_type(Pattern[/\Aconf\z/, /\Apref\z/, /\Alist\z/], $setting_type) |$a, $b| {
    fail("apt::setting resource name/title must start with either 'conf-', 'pref-' or 'list-'")
  }

  if $priority !~ Integer {
    # need this to allow zero-padded priority.
    assert_type(Pattern[/^\d+$/], $priority) |$a, $b| {
      fail('apt::setting priority must be an integer or a zero-padded integer')
    }
  }

  if ($setting_type == 'list') or ($setting_type == 'pref') {
    $_priority = ''
  } else {
    $_priority = $priority
  }

  $_path = $::apt::config_files[$setting_type]['path']
  $_ext  = $::apt::config_files[$setting_type]['ext']

  if $notify_update {
    $_notify = Class['apt::update']
  } else {
    $_notify = undef
  }

  file { "${_path}/${_priority}${base_name}${_ext}":
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $content,
    source  => $source,
    notify  => $_notify,
  }
}
