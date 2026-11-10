# frozen_string_literal: true

module RedmineServerless
  # On Redmine's settings page, disables the inputs of the settings fixed on
  # Lambda, and of the repository types other than LambdaSettings::SCM, and
  # explains why. The page templates are not replaced; without JavaScript the
  # values are still fixed (LambdaSettings).
  class Hooks < Redmine::Hook::ViewListener
    INPUTS = LambdaSettings::FIXED.keys.map { |name| "settings[#{name}]" }

    def view_layouts_base_html_head(context = {})
      return '' unless RedmineServerless.lambda? && context[:controller].is_a?(SettingsController)

      javascript_tag(<<~JS)
        document.addEventListener('DOMContentLoaded', function() {
          var note = #{l(:text_serverless_setting_fixed).to_json};
          var scm = #{LambdaSettings::SCM.to_json};
          function fix(input, box) {
            input.disabled = true;
            input.checked = false;
            if (box && !box.querySelector('.serverless-fixed')) {
              var em = document.createElement('em');
              em.className = 'info serverless-fixed';
              em.textContent = note;
              box.appendChild(em);
            }
          }
          #{INPUTS.to_json}.forEach(function(name) {
            document.querySelectorAll('input[name="' + name + '"]').forEach(function(input) {
              if (input.type !== 'hidden') { fix(input, input.closest('fieldset') || input.closest('p')); }
            });
          });
          document.querySelectorAll('input[name="settings[enabled_scm][]"]').forEach(function(input) {
            if (input.type !== 'hidden' && scm.indexOf(input.value) < 0) { fix(input, input.closest('td')); }
          });
        });
      JS
    end
  end
end
