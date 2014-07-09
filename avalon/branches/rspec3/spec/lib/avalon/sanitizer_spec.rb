require 'spec_helper'
require 'avalon/sanitizer'

describe Avalon::Sanitizer do
  describe '#sanitize' do
    it 'replaces blacklisted characters' do
      expect(Avalon::Sanitizer.sanitize('abcdefg&',['&','_'])).to eq('abcdefg_')
    end

    it 'replaces multiple blacklisted characters' do
      expect(Avalon::Sanitizer.sanitize('avalon*media&system',['*&','__'])).to eq('avalon_media_system')
    end

    it 'does not modify a string without any blacklisted characters' do
      expect(Avalon::Sanitizer.sanitize('avalon_media_system',['*&','__'])).to eq('avalon_media_system')
    end
  end
end
