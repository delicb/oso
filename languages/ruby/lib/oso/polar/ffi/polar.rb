# frozen_string_literal: true

module Oso
  module Polar
    module FFI
      # Wrapper class for Polar FFI pointer + operations.
      class Polar < ::FFI::AutoPointer
        Rust = Module.new do
          extend ::FFI::Library
          ffi_lib FFI::LIB_PATH

          attach_function :new, :polar_new, [], FFI::Polar
          attach_function :load_str, :polar_load, [FFI::Polar, :string, :string], :int32
          attach_function :next_inline_query, :polar_next_inline_query, [FFI::Polar, :uint32], FFI::Query
          attach_function :new_id, :polar_get_external_id, [FFI::Polar], :uint64
          attach_function :new_query_from_str, :polar_new_query, [FFI::Polar, :string, :uint32], FFI::Query
          attach_function :new_query_from_term, :polar_new_query_from_term, [FFI::Polar, :string, :uint32], FFI::Query
          attach_function :register_constant, :polar_register_constant, [FFI::Polar, :string, :string], :int32
          attach_function :free, :polar_free, [FFI::Polar], :int32
        end
        private_constant :Rust

        # @return [FFI::Polar]
        # @raise [FFI::Error] if the FFI call returns an error.
        def self.create
          polar = Rust.new
          raise FFI::Error.get if polar.null?

          polar
        end

        # @param src [String]
        # @param filename [String]
        # @raise [FFI::Error] if the FFI call returns an error.
        def load_str(src, filename: nil)
          raise FFI::Error.get if Rust.load_str(self, src, filename).zero?
        end

        # @return [FFI::Query] if there are remaining inline queries.
        # @return [nil] if there are no remaining inline queries.
        # @raise [FFI::Error] if the FFI call returns an error.
        def next_inline_query
          query = Rust.next_inline_query(self, 0)
          query.null? ? nil : query
        end

        # @return [Integer]
        # @raise [FFI::Error] if the FFI call returns an error.
        def new_id
          id = Rust.new_id(self)
          # TODO(gj): I don't think this error check is correct. If getting a new ID fails on the
          # Rust side, it'll probably surface as a panic (e.g., the KB lock is poisoned).
          raise FFI::Error.get if id.zero?

          id
        end

        # @param str [String] Query string.
        # @return [FFI::Query]
        # @raise [FFI::Error] if the FFI call returns an error.
        def new_query_from_str(str)
          query = Rust.new_query_from_str(self, str, 0)
          raise FFI::Error.get if query.null?

          query
        end

        # @param term [Hash<String, Object>]
        # @return [FFI::Query]
        # @raise [FFI::Error] if the FFI call returns an error.
        def new_query_from_term(term)
          query = Rust.new_query_from_term(self, JSON.dump(term), 0)
          raise FFI::Error.get if query.null?

          query
        end

        # @param name [String]
        # @param value [Hash<String, Object>]
        # @raise [FFI::Error] if the FFI call returns an error.
        def register_constant(name, value:)
          raise FFI::Error.get if Rust.register_constant(self, name, JSON.dump(value)).zero?
        end
      end
    end
  end
end
