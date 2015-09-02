require 'spec_helper'

describe 'Api' do
  let!(:student_dataset) { FactoryGirl.create(:dataset_description, en_title: 'students', is_active: true, api_access_level: Api::REGULAR, with_dataset: true) }
  let!(:student_name_field) { FactoryGirl.create(:field_description, identifier: 'name', dataset_description: student_dataset) }
  let!(:peter_student_record) { student_dataset.dataset_model.create!(name: 'Peter', record_status: Dataset::RecordStatus.find(:published)) }

  let!(:school_dataset) { FactoryGirl.create(:dataset_description, en_title: 'Schools', is_active: true, api_access_level: Api::REGULAR, with_dataset: true) }
  let!(:school_name_field) { FactoryGirl.create(:field_description, identifier: 'name', dataset_description: school_dataset) }
  let!(:grammar_school_record) { school_dataset.dataset_model.create!(name: 'Grammar', record_status: Dataset::RecordStatus.find(:published)) }

  context 'registered user' do
    before(:each) do
      login_as(admin_user)
    end

    it 'is able to download dataset records in csv', use_dump: true do
      export_dump_for_dataset(student_dataset)

      visit dataset_path(id: student_dataset, locale: :en)

      click_link 'dataset_records_in_csv'
      content_type.should be_csv
      page.should have_text 'Peter'
    end

    it 'is able to download dataset description in xml' do
      visit dataset_path(id: student_dataset, locale: :en)

      click_link 'dataset_description_in_xml'

      content_type.should be_xml
      page_should_have_content_with 'students', 'name'
    end

    it 'is able to download dataset relations xml' do
      set_up_relation(student_dataset, school_dataset)

      peter_student_record.ds_schools << grammar_school_record
      peter_student_record.save!

      visit dataset_path(id: student_dataset, locale: :en)

      click_link 'dataset_relations_xml'
      content_type.should be_xml
      page_should_have_content_with 'Kernel::DsStudent', 'Kernel::DsSchool'
    end

    it 'is able to download changes in records' do
      peter_student_record.update_attributes(name: 'Daniel', quality_status: 'ok')

      visit dataset_path(id: student_dataset, locale: :en)

      click_link 'dataset_changes_in_xml'
      content_type.should be_xml
      page_should_have_content_with 'Peter', 'Daniel'
    end
  end
end