#!/usr/bin/env ruby

require 'test/unit/assertions'
require 'stringio'
require 'pp'

include Test::Unit::Assertions

# typedef struct {
#   EFI_GUID                 Name;
#   EFI_FFS_INTEGRITY_CHECK  IntegrityCheck;
#   EFI_FV_FILETYPE          Type;
#   EFI_FFS_FILE_ATTRIBUTES  Attributes;
#   UINT8                    Size[3];
#   EFI_FFS_FILE_STATE       State;
# } EFI_FFS_FILE_HEADER;

# typedef union {
#   struct {
#     UINT8  Header;
#     UINT8  File;
#   }        Checksum;
#   UINT16   TailReference;
# } EFI_FFS_INTEGRITY_CHECK;

EFI_GUID = 'VvvC8' # UINT32, UINT16, UINT16, UINT8[8]
EFI_FV_FILETYPE = 'C' # UINT8
EFI_FFS_FILE_ATTRIBUTES = 'C' # UINT8
EFI_FFS_FILE_STATE = 'C' # UINT8

EFI_CONFIG_FILE_NAME_GUID = [ 0x98B8D59B, 0xE8BA, 0x48EE, 0x98, 0xDD, 0xC2, 0x95, 0x39, 0x2F, 0x1E, 0xDB ].pack(EFI_GUID)
EFI_FV_FILETYPE_RAW = [ 0x01 ].pack(EFI_FV_FILETYPE)
FFS_ATTRIB_CHECKSUM = [ 0x40 ].pack(EFI_FFS_FILE_ATTRIBUTES)

Struct.new('File', :name, :checksum, :type, :attributes, :size, :state)

#####

ARGF.binmode
scap = StringIO.new(ARGF.file.read)
scap.pos = scap.string.index(EFI_CONFIG_FILE_NAME_GUID)

#####

header = Struct::File.new

header.name = scap.read(16)
assert_equal EFI_CONFIG_FILE_NAME_GUID, header.name

header.checksum = scap.read(2)

header.type = scap.read(1)
assert_equal EFI_FV_FILETYPE_RAW, header.type

header.attributes = scap.read(1)
assert_equal FFS_ATTRIB_CHECKSUM, header.attributes

header.size = scap.read(3)

header.state = scap.read(1)

#####

count = header.size.unpack('C3')
count = count.pop << 16 | count.pop << 8 | count.pop
raw = scap.read(count - 24)
assert_equal "\0\0", raw.slice(-2, 2)

#####

config = Hash.new

raw.strip.lines.inject(nil) do |key, line|
  line.strip!

  next key if line.nil?

  if line.start_with?('[') && line.end_with?(']')
    key = line.slice(1...-1)
    config[key] ||= Hash.new
  elsif line.include? '='
    value = line.split('=')
    value.map!(&:strip!)

    unless key.nil?
      config[key].store(value[0], value[1])
    end
  end

  next key
end

pp config
