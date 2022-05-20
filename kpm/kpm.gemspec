# frozen_string_literal: true

#
# Copyright 2014 The Billing Project, LLC
#
# The Billing Project licenses this file to you under the Apache License, version 2.0
# (the "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at:
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations
# under the License.
#

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'kpm/version'

Gem::Specification.new do |s|
  s.name        = 'kpm'
  s.version     = KPM::VERSION
  s.summary     = 'Kill Bill package manager.'
  s.description = 'A package manager for Kill Bill.'

  s.required_ruby_version = '>= 1.8.6'

  s.license = 'Apache License (2.0)'

  s.author   = 'Kill Bill core team'
  s.email    = 'killbilling-users@googlegroups.com'
  s.homepage = 'http://kill-bill.org'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.bindir        = 'bin'
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.rdoc_options << '--exclude' << '.'

  s.add_dependency 'highline', '~> 1.6.21'
  s.add_dependency 'killbill-client', '~> 3.2'
  s.add_dependency 'rubyzip', '>= 1.3', '< 2.4'
  s.add_dependency 'thor', '~> 0.19.1'

  s.add_development_dependency 'gem-release', '~> 2.2'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rspec', '~> 3.9'
  s.add_development_dependency 'rubocop', '~> 0.88.0' if RUBY_VERSION >= '2.4'
end
