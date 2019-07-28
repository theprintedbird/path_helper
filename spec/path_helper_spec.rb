require 'spec_helper'
require_relative '../lib/path_helper.rb'

describe PathHelper do

  context "CLI" do
    shared_context "via the library" do
      When(:helped) { PathHelper::CLI.new( options).paths  }
    end
    shared_context "via the exe" do
      When(:helped) { %x!exe/path_helper #{options}!  }
    end
    context "PATH" do
      Given(:expected) { "/opt/pkg/bin:/opt/pkg/sbin:$HOME/gopath:$HOME/gopath/bin:#{ENV["HOME"]}/.oh-my-zsh/custom/plugins/fzf/bin:#{ENV["HOME"]}/Library/Haskell/bin:#{ENV["HOME"]}/go/bin:#{ENV["HOME"]}/Library/Frameworks/Opam.framework/Programs:#{ENV["HOME"]}/Library/Frameworks/Crystal.framework/Programs:#{ENV["HOME"]}/Library/Frameworks/Crystal.framework/Versions/Current/embedded/bin:#{ENV["HOME"]}/Library/Frameworks/Erlang.framework/Programs:#{ENV["HOME"]}/bin:#{ENV["HOME"]}/.pyenv/bin:/opt/local/bin:/usr/local/MacGPG2/bin:/usr/local/go/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"}
      context "-p" do
        context "via the library" do
          include_context "via the library"
          Given(:options){ {path: false} }
          Then { expected == helped }
        end
        context "via the exe" do
          include_context "via the exe"
          Given(:options){ "-p" }
          Then { expected == helped }
        end
      end
      context %q!-p ""! do
        context "via the library" do
          include_context "via the library"
          Given(:options){ {path: ""} }
          Then { expected == helped }
        end
        context "via the exe" do
          include_context "via the exe"
          Given(:options){ '-p ""' }
          Then { expected == helped }
        end
      end
    end
    context "DYLD_FALLBACK_FRAMEWORK_PATH" do
      context "--dyld-fram" do
        context "via the library" do
          include_context "via the library"
          Given(:options){ {dyld_fram: true} }
          Then { helped == "" }
        end
        context "via the exe" do
          include_context "via the exe"
          Given(:options){ "--dyld-fram" }
          Then { helped == "" }
        end
      end
      context %q!--dyld-fram ""! do
        context "via the library" do
          include_context "via the library"
          Given(:options){ {dyld_fram: ""} }
          Then { helped == "" }
        end
        context "via the exe" do
          include_context "via the exe"
          Given(:options){ '--dyld-fram ""' }
          Then { helped == "" }
        end
      end
    end
    context "DYLD_LIBRARY_LIBRARY_PATH" do
      Given(:expected) {"/opt/pkg/lib:/opt/local/lib:#{ENV["HOME"]}/lib:/usr/local/lib:/usr/lib:/lib"}
      context "--dyld-lib" do      
        context "via the library" do
          include_context "via the library"
          Given(:options){ {dyld_lib: true} }
          Then { helped == expected }
        end
        context "via the exe" do
          include_context "via the exe"
          Given(:options){ "--dyld_fram" }
          Then { helped == "" }
        end
      end
      context %q!--dyld-lib ""! do
        context "via the library" do
          include_context "via the library"
          Given(:options){ {dyld_lib: ""} }
          Then { helped == expected }
        end
        context "via the exe" do
          include_context "via the exe"
          Given(:options){ '--dyld_fram ""' }
          Then { helped == "" }
        end
      end
    end
    context "C_INCLUDED_PATH" do
      Given(:expected) { "/opt/pkg/include:/opt/local/include:/usr/local/include:/usr/include" }
      context "-ci" do
        context "via the library" do
          include_context "via the library"
          Given(:options){ {ci: true} }
          Then { expected == helped}
        end
        context "via the exe" do
          include_context "via the exe"
          Given(:options){ '-c' }
          Then { expected == helped}
        end        
      end
      context '-ci ""' do
        context "via the library" do
          include_context "via the library"
          Given(:options){ {ci: ""} }
          Then { expected == helped}
        end
        context "via the exe" do
          include_context "via the exe"
          Given(:options){ '-c ""' }
          Then { expected == helped}
        end        
      end
    end
    context "MANPATH" do
      Given(:expected) { "#{ENV["HOME"]}/.oh-my-zsh/custom/plugins/fzf/man:/usr/local/MacGPG2/share/man:/opt/local/share/man:/opt/pkg/share/man:/Applications/Xcode.app/Contents/Developer/usr/share/man:/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/share/man:/usr/share/man:/usr/local/share/man" }
      context "-m" do
        context "via the library" do
          include_context "via the library"
          Given(:options){ {man: true} }
          Then { expected == helped }
        end
        context "via the exe" do
          include_context "via the exe"
          Given(:options){ "-m" }
          Then { expected == helped }
        end        
      end
      context %q!-m ""! do
        context "via the library" do
          include_context "via the library"
          Given(:options){ {man: ""} }
          Then { expected == helped }
        end
        context "via the exe" do
          include_context "via the exe"
          Given(:options){ '-m ""' }
          Then { expected == helped }
        end
        
      end
    end
  end


  describe "Entries" do
    describe "path_format" do
      Given(:path){ %w{~ ~/exe /usr/local /usr /opt/local /usr/local} }
      When(:path_formatted) { PathHelper::Entries.path_format path }
      Then { path_formatted == "#{ENV["HOME"]}:#{ENV["HOME"]}/exe:/usr/local:/usr:/opt/local" }
    end
  end
end
