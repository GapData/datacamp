# -*- encoding : utf-8 -*-
class Dataset::DcUpdate < Dataset::DatasetRecord
  set_table_name "dc_updates"
  
  belongs_to :updateable, polymorphic: true
end
