
$:.unshift('lib')

require 'ruote/engine'
require 'ruote/worker'
require 'ruote/part/storage_participant'
require 'ruote/storage/hash_storage'
require 'ruote/storage/fs_storage'

#opts = { 's_logger' => [ 'ruote/log/test_logger', 'Ruote::TestLogger' ] }
opts = {}

storage = if ARGV.include?('--fs')
  FileUtils.rm_rf('work') if ARGV.include?('-e')
  Ruote::FsStorage.new('work', opts)
else
  Ruote::HashStorage.new(opts)
end

p storage.class

if ARGV.include?('-e')
  #
  # engine and worker
  #

  puts "... engine + worker ..."

  engine = Ruote::Engine.new(Ruote::Worker.new(storage))

  engine.register_participant 'alpha', Ruote::StorageParticipant

  start = Time.now

  pdef = Ruote.process_definition :name => 'mega' do
    #echo '${f:index}'
    alpha
  end

  (1..2000).to_a.each_with_index do |i|
    engine.launch(pdef, :fields => { 'index' => i })
  end

  puts "took #{Time.now - start} seconds to launch"

  engine.context.worker.run_thread.join

else
  #
  # pure worker
  #

  puts "... worker ..."

  worker = Ruote::Worker.new(storage)
  worker.run_in_thread
  worker.run_thread.join

end

