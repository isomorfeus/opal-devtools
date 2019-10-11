class OpalConsole < LucidMaterial::Component::Base
  WELCOME_MESSAGE = <<~TEXT
  Welcome to Opal Developer Tools!
  Powered by Isomorfeus - the isomorphic, full stack Ruby application development environment -> isomorfeus.com
  Type 'help' for available commands.
  Type 'CTRL-?' to insert a '?' on keyboards where 'SHIFT-?' doesn't work.
  TEXT

  HELP_TEXT = <<~TEXT
  Available commands:
  inject_opal - inject Opal into current page, only works if the page does not have Opal already.
  debug_devtools - toggle debugging mode for Opal DevTools, shows generated code and other things.
  clear_screen - clear screen
  go_iso - visit the Isomorfeus Project website

  Anything else is interpreted as ruby code and executed in the context of the web page.
  TEXT

  state.count = 1
  state.debug = false
  ref :console

  event_handler :focus do |_|
    ruby_ref(:console).current.focus
  end

  def is_firefox?
    `navigator.userAgent.indexOf('Firefox') >= 0`
  end

  def carriage_return
    state.count(state.count + 1) do
      ruby_ref(:console).current.carriage_return
    end
  end

  def console_log(message)
    ruby_ref(:console).current.log(message)
  end

  def ruby_to_javascript(ruby_code, raw: false)
    compiled_ruby_code = Opal::Compiler.new(ruby_code, irb: true).compile
    compiled_ruby_code = compiled_ruby_code.lines[1..-1].join("\n") # remove /* Generated by Opal 1.0.0 */
    javascript = <<~JAVASCRIPT
      var opal_devtools_final_result = null;
      var caught = false;

      try {
        var opal_devtools_eval_result = #{compiled_ruby_code}
      } catch (e) {
        caught = true;
        opal_devtools_final_result = '' + (e.name ? e.name : 'error')  + ': ' + (e.message ? e.message : 'undefined');
      }
      
      if (!caught) { 
        if (typeof opal_devtools_eval_result === 'undefined') { opal_devtools_final_result = 'undefined' }
        else if (opal_devtools_eval_result === null) { opal_devtools_final_result = 'null' }
        else if (opal_devtools_eval_result === Opal.nil) { opal_devtools_final_result = 'nil' }
    JAVASCRIPT
    if raw
      javascript += <<~JAVASCRIPT
        else if (typeof opal_devtools_eval_result !== 'string' && typeof opal_devtools_eval_result.$inspect === 'function') {
          opal_devtools_final_result = opal_devtools_eval_result.$inspect(); }
        else if (typeof opal_devtools_eval_result !== 'string' && typeof opal_devtools_eval_result.$to_n === 'function') {
          opal_devtools_final_result = opal_devtools_eval_result.$to_n(); }
      JAVASCRIPT
    else
      javascript += <<~JAVASCRIPT
        else if (typeof opal_devtools_eval_result.$inspect === 'function') {
          opal_devtools_final_result = opal_devtools_eval_result.$inspect(); }
        else if (typeof opal_devtools_eval_result.$to_n === 'function') {
          opal_devtools_final_result = opal_devtools_eval_result.$to_n(); }
      JAVASCRIPT
    end
    javascript += <<~JAVASCRIPT
        else { opal_devtools_final_result = opal_devtools_eval_result }
      }
      opal_devtools_final_result;
    JAVASCRIPT
    javascript
  end

  def execute_in_page(ruby_code)
    javascript_code = ruby_to_javascript(ruby_code)
    console_log(javascript_code) if state.debug

    # Property "useContentScriptContext" is unsupported by Firefox
    if app_store.inject_mode
      if is_firefox?
        %x{
          let tabId = chrome.devtools.inspectedWindow.tabId;
          global.BackgroundConnection.postMessage({ tabId: tabId, injectCode: javascript_code, completion: false })
        }
      else
        %x{
          chrome.devtools.inspectedWindow.eval(javascript_code, { useContentScriptContext: true }, function(result, exception_info) {
            #{console_log(`result`)}
            if (exception_info) {
              if (exception_info.isError) { #{console_log(`exception_info.description`)} }
              if (exception_info.isException) { #{console_log(`exception_info.value`)} }
            }
            #{carriage_return}
          });
        }
      end
    else
      %x{
        chrome.devtools.inspectedWindow.eval(javascript_code, {}, function(result, exception_info) {
          #{console_log(`result`)}
          if (exception_info) {
            if (exception_info.isError) { #{console_log(`exception_info.description`)} }
            if (exception_info.isException) { #{console_log(`exception_info.value`)} }
          }
          #{carriage_return}
        });
      }
    end
  end

  def inject_to_page
    unless app_store.inject_mode
      %x{
        let tabId = chrome.devtools.inspectedWindow.tabId;
        window.addEventListener('OpalDevtoolsResult', function(event) {
          let message = event.detail;
          if (message && message.tabId == tabId) {
            if (message.fromConsole) {
              if (message.result) {
                if (message.completion) {
                  let parsed_result = JSON.parse(message.result);
                  #{ruby_ref(:console)&.current&.show_completions(`parsed_result[2]`, `parsed_result[1]`)}
                } else {
                  #{console_log(`message.result[0]`)}
                  #{carriage_return}
                }
              }
            }
          }
        });
      }
    end
    %x{
      let tabId = chrome.devtools.inspectedWindow.tabId;
      chrome.devtools.inspectedWindow.eval("if (typeof Opal !== 'undefined') { Opal.RUBY_ENGINE_VERSION }", {}, function(result, exception_info) {
        if (!result) {
          global.BackgroundConnection.postMessage({ tabId: tabId, injectScript: "/devtools/panel/opal-inject.js" });
          #{app_store.inject_mode = true};
          #{console_log("Opal injected into Page.")};
        } else {
          #{console_log("Page already has Opal version #{`result`}")}
        }
        #{carriage_return}
      })
    }
  end

  def handler(command)
    begin
      if command.start_with?('help')
        console_log(HELP_TEXT)
        carriage_return
      elsif command.start_with?('inject_opal')
        inject_to_page
      elsif command.start_with?('debug_devtools')
        state.debug(!state.debug) do
          console_log("debug: #{state.debug}")
          carriage_return
        end
      elsif command.start_with?('clear_screen')
        ruby_ref(:console).current.clear_screen
        carriage_return
      elsif command.start_with?('go_iso')
        javascript_code = "window.location='http://isomorfeus.com'"
        %x{
          chrome.devtools.inspectedWindow.eval(javascript_code, {}, function(result, exception_info) {
            #{app_store.inject_mode = false}
            #{console_log("Welcome to the Isomorfeus Project :)")}
            #{console_log("A first command to try: Isomorfeus.on_browser?")}
            #{carriage_return}
          })
        }
      else
        execute_in_page(command)
      end
    rescue Exception => e
      console_log(e.message)
      carriage_return
    end
  end

  def engine_source
    @engine_source ||= `Opal.modules["components/opal_devtools/completion_engine"].toString()`
  end

  def completion(prompt_text)
    ruby_code = <<~RUBY
      OpalDevtools::CompletionEngine.complete("#{prompt_text}")
    RUBY
    javascript_code = ruby_to_javascript(ruby_code, raw: true)
    if app_store.inject_mode
      if is_firefox?
        %x{
          let tabId = chrome.devtools.inspectedWindow.tabId;
          global.BackgroundConnection.postMessage({ tabId: tabId, injectCode: javascript_code, completion: true })
        }
      else
        %x{
            chrome.devtools.inspectedWindow.eval(javascript_code, { useContentScriptContext: true }, function(result, exception_info) {
              let parsed_result = JSON.parse(result);
              #{ruby_ref(:console)&.current&.show_completions(`parsed_result[2]`, `parsed_result[1]`)}
              if (exception_info) {
                if (exception_info.isError) { #{console_log(`exception_info.description`)} }
                if (exception_info.isException) { #{console_log(`exception_info.value`)} }
              }
              #{carriage_return}
            });
          }
      end
    else
      # magic ...
      javascript_prelude = <<~JAVASCRIPT
        if (!Opal.modules["components/opal_devtools/completion_engine"]) {
          Opal.modules["components/opal_devtools/completion_engine"] = #{engine_source};
        }
        Opal.load("components/opal_devtools/completion_engine");
      JAVASCRIPT
      javascript_code = javascript_prelude + javascript_code
      %x{
        chrome.devtools.inspectedWindow.eval(javascript_code, {}, function(result, exception_info) {
          let parsed_result = JSON.parse(result);
          #{ruby_ref(:console)&.current&.show_completions(`parsed_result[2]`, `parsed_result[1]`)}
          if (exception_info) {
            if (exception_info.isError) { #{console_log(`exception_info.description`)} }
            if (exception_info.isException) { #{console_log(`exception_info.value`)} }
          }
          #{carriage_return}
        });
      }
    end
  end

  render do
    Console(key: 'oc', ref: ref(:console), autofocus: true, prompt_label: "#{state.count} > ", welcome_message: WELCOME_MESSAGE, on_click: :focus,
            handler: proc { |c| handler(c) },
            complete: proc { |t| completion(t) })
  end

  def window_click_handler
    @window_click_handler ||= %x{
                                function(event) {
                                  #{ruby_ref(:console)&.current&.focus}
                                }
                              }
  end

  component_did_mount do
    `window.addEventListener('click', #{window_click_handler})`
    ruby_ref(:console)&.current&.focus
  end

  component_will_unmount do
    `window.removeEventListener('click', #{window_click_handler})`
  end
end
