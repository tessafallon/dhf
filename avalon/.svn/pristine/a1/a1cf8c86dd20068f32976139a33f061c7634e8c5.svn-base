require 'avalon/file_resolver'

describe Avalon::FileResolver do
  let(:resolver){ Avalon::FileResolver.new }
  describe "#path_to" do
    it 'returns umodified path when string already has a schema' do
      expect(resolver.path_to('http://example.com')).to eq('http://example.com')
    end
    it 'returns path with schema' do
      allow(resolver).to receive(:mount_map).and_return({'/Volumes/dropbox/'=> 'smb://example.edu/dropbox'})
      expect(resolver.path_to('/Volumes/dropbox/master_files/')).to eq('smb://example.edu/dropbox/master_files')
    end
    it 'returns path with file schema when no mounts match' do
      allow(resolver).to receive(:mount_map).and_return({})
      expect(resolver.path_to('/storage/master_files/')).to eq('file:///storage/master_files/')
    end
  end

  describe "#mount_map" do
    it 'returns a formatted mount' do
      allow(resolver).to receive(:overrides).and_return({})
      resolver.instance_variable_set(:@mounts, ['//adam@example.edu/dropbox on /Volumes/dropbox (smbfs, nodev, nosuid, mounted by adam)'])
      expect(resolver.mount_map).to eq({'/Volumes/dropbox/'=>'smb://example.edu/dropbox'})
    end
  end
end
