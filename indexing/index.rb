#!/usr/bin/ruby
#
# Script to index some MARC records using Traject and blacklight-marc.
# This is hacked together from various pieces in Blacklight.

# add pwd to load path so traject can find translation_maps
$:.unshift './'

require 'traject'
require 'blacklight'
require 'blacklight/marc'
require 'marc'


# patch connection_config because we don't have a full
# blacklight/rails environment
module Blacklight
  def self.connection_config
    { 'url': ENV['SOLR_URL'] || 'http://localhost:8983/solr/lumen-core' }
  end
end


# patch this module to get some fixes: see https://github.com/projectblacklight/blacklight-marc/pull/37
module Blacklight::Marc::Indexer::Formats
  module FormatMap
    def self.map007(v, vals)
      field007hasC = false
      v = v.upcase
      case
      when (v.start_with? 'A')
        vals << (v == 'AD') ? 'Atlas' : 'Map'
      when (v.start_with? 'C')
        case
        when (v == "CA")
          vals << "TapeCartridge"
        when (v == "CB")
          vals << "ChipCartridge"
        when (v == "CC")
          vals << "DiscCartridge"
        when (v == "CF")
          vals << "TapeCassette"
        when (v == "CH")
          vals << "TapeReel"
        when (v == "CJ")
          vals << "FloppyDisk"
        when (v == "CM")
          vals << "CDROM"
        when (v == "C0")
          vals << "CDROM"
        when (v == "CR")
          # Do not return - this will cause anything with an 856 field to be labeled as "Electronic"
          field007hasC = true
        else
          vals << "Software"
        end
      when (v.start_with? 'D')
        vals << 'Globe'
      when (v.start_with? 'F')
        vals << 'Braille'
      when (v.start_with? 'G')
        if (v == "GC")
          vals << "Filmstrip"
        elsif (v == "GD")
          vals << "Filmstrip"
        elsif (v == "GT")
          vals << "Transparency"
        else
          vals << "Slide"
        end
      when (v.start_with? 'H')
        vals << "Microfilm"
      when (v.start_with? 'K')
        case
        when (v == "KC")
          vals << "Collage"
        when (v == "KD")
          vals << "Drawing"
        when (v == "KE")
          vals << "Painting"
        when (v == "KF")
          vals << "Print"
        when (v == "KG")
          vals << "Photonegative"
        when (v == "KJ")
          vals << "Print"
        when (v == "KL")
          vals << "Drawing"
        when (v == "K0")
          vals << "FlashCard"
        when (v == "KN")
          vals << "Chart"
        else
          vals << "Photo"
        end
      when (v.start_with? 'M')
        if (v == "MF")
          vals << "VideoCassette"
        elsif (v == "MR")
          vals << "Filmstrip"
        else
          vals << "MotionPicture"
        end
      when (v.start_with? 'O')
        vals << 'Kit'
      when (v.start_with? 'Q')
        vals << 'MusicalScore'
      when (v.start_with? 'R')
        vals << 'SensorImage'
      when (v.start_with? 'S')
        if (v == "SD")
          vals << "SoundDisc"
        elsif (v == "SS")
          vals << "SoundCassette"
        else
          vals << "SoundRecording"
        end
      when (v.start_with? 'V')
        if (v == "VC")
          vals << "VideoCartridge"
        elsif (v == "VD")
          vals << "VideoDisc"
        elsif (v == "VF")
          vals << "VideoCassette"
        elsif (v == "VR")
          vals << "VideoReel"
        else
          vals << "Video"
        end
      end
      field007hasC
    end

    def self.map_leader(f_000,field007hasC,vals,record)
      f_000 = f_000.upcase
      case
      when (f_000.start_with? 'C')
        vals << "MusicalScore"
      when (f_000.start_with? 'D')
        vals << "MusicalScore"
      when (f_000.start_with? 'E')
        vals << "Map"
      when (f_000.start_with? 'F')
        vals << "Map"
      when (f_000.start_with? 'I')
        vals << "SoundRecording"
      when (f_000.start_with? 'J')
        vals << "MusicRecording"
      when (f_000.start_with? 'K')
        vals << "Photo"
      when (f_000.start_with? 'M')
        vals << "Electronic"
      when (f_000.start_with? 'O')
        vals << "Kit"
      when (f_000.start_with? 'P')
        vals << "Kit"
      when (f_000.start_with? 'R')
        vals << "PhysicalObject"
      when (f_000.start_with? 'T')
        vals << "Manuscript"
      when (f_000.start_with? 'A')
        if f_000 == 'AM'
          vals << ((field007hasC) ? "eBook" : "Book")
        elsif f_000 == 'AS' 
          # Look in 008 to determine what type of Continuing Resource
          format_code = Traject::Macros::Marc21.extract_marc_from(record, "008[21]", first: true, default: "").first.upcase
          if format_code == 'N'
            vals << 'Newspaper'
          elsif format_code == 'P'
            vals << 'Journal'
          else
            vals << 'Serial'
          end
        end
      end
      vals
    end
  end
  def get_format(options = {})
    lambda do |record, accumulator, context|
      vals = []
      extractor = Traject::MarcExtractor.new('245h', options)
      extractor.extract(record).select do |v|
        vals << 'Electronic' if v =~ /electronic\sresource/
      end
      unless vals.empty?
        vals.uniq!
        accumulator.concat vals
      else
        field007hasC = false
        extractor = Traject::MarcExtractor.new('007[0-1]', options)
        extractor.extract(record).each {|v| field007hasC ||= FormatMap.map007(v,vals)}
        unless vals.empty?
          vals.uniq!
          accumulator.concat vals
        else
          # check the Leader - this is NOT a repeating field
          # if we find a matching value there, grab it and return.
          FormatMap.map_leader(record.leader[6,2],field007hasC,vals,record)
          unless vals.empty?
            vals.uniq!
            accumulator.concat vals
          else
            FormatMap.map_leader(record.leader[6],field007hasC,vals,record)
            if vals.empty?
              accumulator.concat ['Unknown']
            else
              vals.uniq!
              accumulator.concat vals
            end
          end
        end
      end
    end
  end
end


# This is a copy of the stock class created by the Blacklight generator.
class MarcIndexer < Blacklight::Marc::Indexer
  # this mixin defines lambda facotry method get_format for legacy marc formats
  include Blacklight::Marc::Indexer::Formats

  def initialize
    super

    settings do
      # type may be 'binary', 'xml', or 'json'
      provide "marc_source.type", "binary"
      # set this to be non-negative if threshold should be enforced
      provide 'solr_writer.max_skipped', -1
    end

    to_field "id", trim(extract_marc("001"), :first => true)
    to_field 'marc_display', get_xml
    to_field "text", extract_all_marc_values do |r, acc|
      acc.replace [acc.join(' ')] # turn it into a single string
    end
     
    to_field "language_facet", marc_languages("008[35-37]:041a:041d:")
    to_field "format", get_format
    to_field "isbn_t",  extract_marc('020a', :separator=>nil) do |rec, acc|
         orig = acc.dup
         acc.map!{|x| StdNum::ISBN.allNormalizedValues(x)}
         acc << orig
         acc.flatten!
         acc.uniq!
    end
     
    to_field 'material_type_display', extract_marc('300a', :trim_punctuation => true)
     
    # Title fields
    #    primary title 
     
    to_field 'title_t', extract_marc('245a')
    to_field 'title_display', extract_marc('245a', :trim_punctuation => true, :alternate_script=>false)
    to_field 'title_vern_display', extract_marc('245a', :trim_punctuation => true, :alternate_script=>:only)
     
    #    subtitle
     
    to_field 'subtitle_t', extract_marc('245b')
    to_field 'subtitle_display', extract_marc('245b', :trim_punctuation => true, :alternate_script=>false)
    to_field 'subtitle_vern_display', extract_marc('245b', :trim_punctuation => true, :alternate_script=>:only)
     
    #    additional title fields
    to_field 'title_addl_t', 
      extract_marc(%W{
        245abnps
        130#{ATOZ}
        240abcdefgklmnopqrs
        210ab
        222ab
        242abnp
        243abcdefgklmnopqrs
        246abcdefgnp
        247abcdefgnp
      }.join(':'))
     
    to_field 'title_added_entry_t', extract_marc(%W{
      700gklmnoprst
      710fgklmnopqrst
      711fgklnpst
      730abcdefgklmnopqrst
      740anp
    }.join(':'))
     
    to_field 'title_series_t', extract_marc("440anpv:490av")
     
    to_field 'title_sort', marc_sortable_title  
     
    # Author fields
     
    to_field 'author_t', extract_marc("100abcegqu:110abcdegnu:111acdegjnqu")
    to_field 'author_addl_t', extract_marc("700abcegqu:710abcdegnu:711acdegjnqu")
    to_field 'author_display', extract_marc("100abcdq:110#{ATOZ}:111#{ATOZ}", :alternate_script=>false)
    to_field 'author_vern_display', extract_marc("100abcdq:110#{ATOZ}:111#{ATOZ}", :alternate_script=>:only)
     
    # JSTOR isn't an author. Try to not use it as one
    to_field 'author_sort', marc_sortable_author
     
    # Subject fields
    to_field 'subject_t', extract_marc(%W(
      600#{ATOU}
      610#{ATOU}
      611#{ATOU}
      630#{ATOU}
      650abcde
      651ae
      653a:654abcde:655abc
    ).join(':'))
    to_field 'subject_addl_t', extract_marc("600vwxyz:610vwxyz:611vwxyz:630vwxyz:650vwxyz:651vwxyz:654vwxyz:655vwxyz")
    to_field 'subject_topic_facet', extract_marc("600abcdq:610ab:611ab:630aa:650aa:653aa:654ab:655ab", :trim_punctuation => true)
    to_field 'subject_era_facet',  extract_marc("650y:651y:654y:655y", :trim_punctuation => true)
    to_field 'subject_geo_facet',  extract_marc("651a:650z",:trim_punctuation => true )
     
    # Publication fields
    to_field 'published_display', extract_marc('260a', :trim_punctuation => true, :alternate_script=>false)
    to_field 'published_vern_display', extract_marc('260a', :trim_punctuation => true, :alternate_script=>:only)
    to_field 'pub_date', marc_publication_date
     
    # Call Number fields
    to_field 'lc_callnum_display', extract_marc('050ab', :first => true)
    to_field 'lc_1letter_facet', extract_marc('050ab', :first=>true, :translation_map=>'callnumber_map') do |rec, acc|
      # Just get the first letter to send to the translation map
      acc.map!{|x| x[0]}
    end

    alpha_pat = /\A([A-Z]{1,3})\d.*\Z/
    to_field 'lc_alpha_facet', extract_marc('050a', :first=>true) do |rec, acc|
      acc.map! do |x|
        (m = alpha_pat.match(x)) ? m[1] : nil
      end
      acc.compact! # eliminate nils
    end

    to_field 'lc_b4cutter_facet', extract_marc('050a', :first=>true)
     
    # URL Fields
     
    notfulltext = /abstract|description|sample text|table of contents|/i
     
    to_field('url_fulltext_display') do |rec, acc|
      rec.fields('856').each do |f|
        case f.indicator2
        when '0'
          f.find_all{|sf| sf.code == 'u'}.each do |url|
            acc << url.value
          end
        when '2'
          # do nothing
        else
          z3 = [f['z'], f['3']].join(' ')
          unless notfulltext.match(z3)
            acc << f['u'] unless f['u'].nil?
          end
        end
      end
    end

    # Very similar to url_fulltext_display. Should DRY up.
    to_field 'url_suppl_display' do |rec, acc|
      rec.fields('856').each do |f|
        case f.indicator2
        when '2'
          f.find_all{|sf| sf.code == 'u'}.each do |url|
            acc << url.value
          end
        when '0'
          # do nothing
        else
          z3 = [f['z'], f['3']].join(' ')
          if notfulltext.match(z3)
            acc << f['u'] unless f['u'].nil?
          end
        end
      end
    end
  end
end

#### main

filename = ARGV[0]
if filename
  open(filename) do |io|
    MarcIndexer.new().process(io)
  end
else
  puts "Specify a marc file to index."
end
