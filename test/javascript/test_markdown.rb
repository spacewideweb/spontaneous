
require File.expand_path('../../test_helper', __FILE__)
require 'test_javascript'

class MarkdownEditorTest < MiniTest::Spec
  include JavascriptTestBase

  #  Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis eget augue leo, et consequat sem. Duis rutrum tortor nec ipsum vestibulum in elementum sem euismod. Nullam lacinia aliquet erat, sit amet mollis neque ultricies ut. Etiam lobortis feugiat condimentum. Sed bibendum vehicula malesuada. Nullam et metus sit amet mi placerat dapibus. Donec facilisis dignissim eros, id placerat tellus blandit vitae. Maecenas sed eros a odio adipiscing egestas a vel orci. Praesent volutpat tempor felis id pretium. Aliquam leo ipsum, tincidunt feugiat porttitor consectetur, scelerisque sed lectus. Proin tristique tristique enim, volutpat auctor felis blandit et. Pellentesque non feugiat lacus.

  def setup
    @page = page
    @page.x(<<-JS)
      var fake_input = function(start, end, value) {
        var array = [];
        array.value = value;
        array[0] = {
          selectionStart: start,
          selectionEnd: end,
          setSelectionRange: function(start, end) {
            this.selectionStart = start;
            this.selectionEnd = end;
          }
        };
        array.val = function(new_value) {
          if (new_value) { this.value = new_value; }
          return this.value;
        };
        return array;
      }
    JS
  end

  def style(command, sel_start, sel_end, value)
    state = @page.x(<<-JS)
      var input = fake_input(#{sel_start}, #{sel_end}, #{value.inspect})
      var command = new Spontaneous.FieldTypes.MarkdownField.#{command}(input)
      command.execute();
      Spontaneous.FieldTypes.MarkdownField.TextCommand.get_state(input)
    JS
    result = Hash[state.to_ary]
    result["value"] = result["before"] + result["middle"] + result["after"]
    result
  end

  context "Editor selection" do
    context "for inline style" do
      [['Bold', "**"], ['Italic', '_']].each do |style, mark|
        context "#{style}" do
          should "expand to word under cursor at beginning if no selection made" do
            state = style(style, 0, 0, "Lorem ipsum")
            state["value"].should == "#{mark}Lorem#{mark} ipsum"
          end
          should "expand to word under cursor if no selection made" do
            state = style(style, 7, 7, "Lorem ipsum dolor")
            state["value"].should == "Lorem #{mark}ipsum#{mark} dolor"
          end
          should "expand to word under cursor at end of text if no selection made" do
            state = style(style, 14, 14, "Lorem ipsum dolor")
            state["value"].should == "Lorem ipsum #{mark}dolor#{mark}"
          end
          should "embolden selected word at start of text" do
            state = style(style, 0, 5, "Lorem ipsum")
            state["value"].should == "#{mark}Lorem#{mark} ipsum"
          end
          should "embolden selected word at end of text" do
            state = style(style, 6, 11, "Lorem ipsum")
            state["value"].should == "Lorem #{mark}ipsum#{mark}"
          end
          should "remove formatting when cursor is within bold word at beginning" do
            state = style(style, 2, 2, "#{mark}Lorem#{mark} ipsum")
            state["value"].should == "Lorem ipsum"
          end
          should "remove formatting when cursor is within bold word at beginning" do
            state = style(style, 10, 10, "Lorem #{mark}ipsum#{mark}")
            state["value"].should == "Lorem ipsum"
          end
          should "not include fullstops in bold when no selection is made at end of text" do
            state = style(style, 7, 7, "Lorem ipsum.")
            state["value"].should == "Lorem #{mark}ipsum#{mark}."
          end
          should "not include fullstops in bold when no selection is made" do
            state = style(style, 7, 7, "Lorem ipsum, dolor.")
            state["value"].should == "Lorem #{mark}ipsum#{mark}, dolor."
          end
          should "be compatible with header tags" do
            state = style(style, 72, 72, "Lorem ipsum \n=============================================\n\ndolor sit amet")
            state["value"].should == "Lorem ipsum \n=============================================\n\ndolor sit #{mark}amet#{mark}"
          end
          should "work across multiple lines with existing styles" do
            state = style(style, 8, 8, "Lorem ipsum\n\ndolor sit #{mark}amet#{mark}")
            state['value'].should == "Lorem #{mark}ipsum#{mark}\n\ndolor sit #{mark}amet#{mark}"
          end
        end
      end
    end
  end
end
