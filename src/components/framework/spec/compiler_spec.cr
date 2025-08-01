require "./spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, <<-CR, line: line
    require "./spec_helper.cr"
    #{code}
    ATH.run
  CR
end

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles <<-CR, line: line
    require "./spec_helper.cr"
    #{code}
    ATH.run
  CR
end

describe Athena::Framework do
  describe "compiler errors", tags: "compiled" do
    it "action parameter missing type restriction" do
      assert_compile_time_error "Route action parameter 'CompileController#action:id' must have a type restriction.", <<-CR
        class CompileController < ATH::Controller
          @[ARTA::Get(path: "/:id")]
          def action(id) : Int32
            123
          end
        end
      CR
    end

    it "action missing return type" do
      assert_compile_time_error "Route action return type must be set for 'CompileController#action'.", <<-CR
        class CompileController < ATH::Controller
          @[ARTA::Get(path: "/")]
          def action
            123
          end
        end
      CR
    end

    it "class method action" do
      assert_compile_time_error "Routes can only be defined as instance methods. Did you mean 'CompileController#class_method'?", <<-CR
        class CompileController < ATH::Controller
          @[ARTA::Get(path: "/")]
          def self.class_method : Int32
            123
          end
        end
      CR
    end

    it "when action does not have a path" do
      assert_compile_time_error "Route action 'CompileController#action' is missing its path.", <<-CR
        class CompileController < ATH::Controller
          @[ARTA::Get]
          def action : Int32
            123
          end
        end
      CR
    end

    describe "when a controller action is mistakenly overridden" do
      it "within the same controller" do
        assert_compile_time_error "A controller action named '#action' already exists within 'CompileController'.", <<-CR
          class CompileController < ATH::Controller
            @[ARTA::Get(path: "/foo")]
            def action : String
              "foo"
            end

            @[ARTA::Get(path: "/bar")]
            def action : String
              "bar"
            end
          end
        CR
      end

      it "within a different controller" do
        assert_compiles <<-CR
          class ExampleController < ATH::Controller
            @[ARTA::Get(path: "/foo")]
            def action : String
              "foo"
            end
          end

          class CompileController < ATH::Controller
            @[ARTA::Get(path: "/bar")]
            def action : String
              "bar"
            end
          end
        CR
      end
    end

    describe ARTA::Route do
      it "when there is a prefix for a controller action with a locale that does not have a route" do
        assert_compile_time_error "Route action 'CompileController#action' is missing paths for locale(s) 'de'.", <<-CR
          @[ARTA::Route(path: {"de" => "/german", "fr" => "/france"})]
          class CompileController < ATH::Controller
            @[ARTA::Get(path: {"fr" => ""})]
            def action : Nil
            end
          end
        CR
      end

      it "when a controller action has a locale that is missing a prefix" do
        assert_compile_time_error "Route action 'CompileController#action' is missing a corresponding route prefix for the 'de' locale.", <<-CR
          @[ARTA::Route(path: {"fr" => "/france"})]
          class CompileController < ATH::Controller
            @[ARTA::Get(path: {"de" => "/foo", "fr" => "/bar"})]
            def action : Nil
            end
          end
        CR
      end

      it "has an unexpected type as the #methods" do
        assert_compile_time_error "Route action 'CompileController#action' expects a 'StringLiteral | ArrayLiteral | TupleLiteral' for its 'ARTA::Route#methods' field, but got a 'NumberLiteral'.", <<-CR
          class CompileController < ATH::Controller
            @[ARTA::Route("/", methods: 123)]
            def action : Nil
            end
          end
        CR
      end

      it "requires ARTA::Route to use 'methods'" do
        assert_compile_time_error "Route action 'CompileController#action' cannot change the required methods when _NOT_ using the 'ARTA::Route' annotation.", <<-CR
          class CompileController < ATH::Controller
            @[ARTA::Get("/", methods: "SEARCH")]
            def action : Nil; end
          end
        CR
      end

      describe "invalid field types" do
        describe "path" do
          it "controller ann" do
            assert_compile_time_error "Route action 'CompileController' expects a 'StringLiteral | HashLiteral(StringLiteral, StringLiteral)' for its 'ARTA::Route#path' field, but got a 'NumberLiteral'.", <<-CR
              @[ARTA::Route(path: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CR
          end

          it "route ann" do
            assert_compile_time_error "Route action 'CompileController#action' expects a 'StringLiteral | HashLiteral(StringLiteral, StringLiteral)' for its 'ARTA::Get#path' field, but got a 'NumberLiteral'.", <<-CR
              class CompileController < ATH::Controller
                @[ARTA::Get(path: 10)]
                def action : Nil; end
              end
            CR
          end
        end

        describe "defaults" do
          it "controller ann" do
            assert_compile_time_error "Route action 'CompileController' expects a 'HashLiteral(StringLiteral, _)' for its 'ARTA::Route#defaults' field, but got a 'NumberLiteral'.", <<-CR
              @[ARTA::Route(defaults: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CR
          end

          it "route ann" do
            assert_compile_time_error "Route action 'CompileController#action' expects a 'HashLiteral(StringLiteral, _)' for its 'ARTA::Get#defaults' field, but got a 'NumberLiteral'.", <<-CR
              class CompileController < ATH::Controller
                @[ARTA::Get(defaults: 10)]
                def action : Nil; end
              end
            CR
          end
        end

        describe "locale" do
          it "controller ann" do
            assert_compile_time_error "Route action 'CompileController' expects a 'StringLiteral' for its 'ARTA::Route#locale' field, but got a 'NumberLiteral'.", <<-CR
              @[ARTA::Route(locale: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CR
          end

          it "route ann" do
            assert_compile_time_error "Route action 'CompileController#action' expects a 'StringLiteral' for its 'ARTA::Get#locale' field, but got a 'NumberLiteral'.", <<-CR
              class CompileController < ATH::Controller
                @[ARTA::Get(locale: 10)]
                def action : Nil; end
              end
            CR
          end
        end

        describe "format" do
          it "controller ann" do
            assert_compile_time_error "Route action 'CompileController' expects a 'StringLiteral' for its 'ARTA::Route#format' field, but got a 'NumberLiteral'.", <<-CR
              @[ARTA::Route(format: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CR
          end

          it "route ann" do
            assert_compile_time_error "Route action 'CompileController#action' expects a 'StringLiteral' for its 'ARTA::Get#format' field, but got a 'NumberLiteral'.", <<-CR
              class CompileController < ATH::Controller
                @[ARTA::Get(format: 10)]
                def action : Nil; end
              end
            CR
          end
        end

        describe "stateless" do
          it "controller ann" do
            assert_compile_time_error "Route action 'CompileController' expects a 'BoolLiteral' for its 'ARTA::Route#stateless' field, but got a 'NumberLiteral'.", <<-CR
              @[ARTA::Route(stateless: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CR
          end

          it "route ann" do
            assert_compile_time_error "Route action 'CompileController#action' expects a 'BoolLiteral' for its 'ARTA::Get#stateless' field, but got a 'NumberLiteral'.", <<-CR
              class CompileController < ATH::Controller
                @[ARTA::Get(stateless: 10)]
                def action : Nil; end
              end
            CR
          end
        end

        describe "name" do
          it "controller ann" do
            assert_compile_time_error "Route action 'CompileController' expects a 'StringLiteral' for its 'ARTA::Route#name' field, but got a 'NumberLiteral'.", <<-CR
              @[ARTA::Route(name: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CR
          end

          it "route ann" do
            assert_compile_time_error "Route action 'CompileController#action' expects a 'StringLiteral' for its 'ARTA::Get#name' field, but got a 'NumberLiteral'.", <<-CR
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/", name: 10)]
                def action : Nil; end
              end
            CR
          end
        end

        describe "requirements" do
          it "controller ann" do
            assert_compile_time_error "Route action 'CompileController' expects a 'HashLiteral(StringLiteral, StringLiteral | RegexLiteral)' for its 'ARTA::Route#requirements' field, but got a 'NumberLiteral'.", <<-CR
              @[ARTA::Route(requirements: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CR
          end

          it "route ann" do
            assert_compile_time_error "Route action 'CompileController#action' expects a 'HashLiteral(StringLiteral, StringLiteral | RegexLiteral)' for its 'ARTA::Get#requirements' field, but got a 'NumberLiteral'.", <<-CR
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/", requirements: 10)]
                def action : Nil; end
              end
            CR
          end
        end

        describe "schemes" do
          it "controller ann" do
            assert_compile_time_error "Route action 'CompileController' expects a 'StringLiteral | Enumerable(StringLiteral)' for its 'ARTA::Route#schemes' field, but got a 'NumberLiteral'.", <<-CR
              @[ARTA::Route(schemes: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CR
          end
        end

        describe "methods" do
          it "controller ann" do
            assert_compile_time_error "Route action 'CompileController' expects a 'StringLiteral | Enumerable(StringLiteral)' for its 'ARTA::Route#methods' field, but got a 'NumberLiteral'.", <<-CR
              @[ARTA::Route(methods: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CR
          end
        end

        describe "host" do
          it "controller ann" do
            assert_compile_time_error "Route action 'CompileController' expects a 'StringLiteral | RegexLiteral' for its 'ARTA::Route#host' field, but got a 'NumberLiteral'.", <<-CR
              @[ARTA::Route(host: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CR
          end

          it "route ann" do
            assert_compile_time_error "Route action 'CompileController#action' expects a 'StringLiteral | RegexLiteral' for its 'ARTA::Get#host' field, but got a 'NumberLiteral'.", <<-CR
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/", host: 10)]
                def action : Nil; end
              end
            CR
          end
        end

        describe "condition" do
          it "controller ann" do
            assert_compile_time_error "Route action 'CompileController' expects an 'ART::Route::Condition' for its 'ARTA::Route#condition' field, but got a 'NumberLiteral'.", <<-CR
              @[ARTA::Route(condition: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CR
          end

          it "route ann" do
            assert_compile_time_error "Route action 'CompileController#action' expects an 'ART::Route::Condition' for its 'ARTA::Get#condition' field, but got a 'NumberLiteral'.", <<-CR
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/", condition: 10)]
                def action : Nil; end
              end
            CR
          end
        end

        describe "priority" do
          it "controller ann" do
            assert_compile_time_error "Route action 'CompileController' expects a 'NumberLiteral' for its 'ARTA::Route#priority' field, but got a 'BoolLiteral'.", <<-CR
              @[ARTA::Route(priority: true)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CR
          end

          it "route ann" do
            assert_compile_time_error "Route action 'CompileController#action' expects a 'NumberLiteral' for its 'ARTA::Get#priority' field, but got a 'BoolLiteral'.", <<-CR
              class CompileController < ATH::Controller
                @[ARTA::Get(priority: false)]
                def action : Nil; end
              end
            CR
          end
        end
      end
    end

    describe ATHR::RequestBody do
      it "when the action parameter is not serializable" do
        assert_compile_time_error " The annotation '@[ATHA::MapRequestBody]' cannot be applied to 'CompileController#action:foo : Foo' since the 'Athena::Framework::Controller::ValueResolvers::RequestBody' resolver only supports parameters of type 'Athena::Serializer::Serializable | JSON::Serializable | URI::Params::Serializable'.", <<-CR
          record Foo, text : String

          class CompileController < ATH::Controller
            @[ARTA::Get(path: "/")]
            def action(@[ATHA::MapRequestBody] foo : Foo) : Foo
              foo
            end
          end
        CR
      end
    end
  end
end
