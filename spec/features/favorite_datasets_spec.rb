require 'spec_helper'

describe 'FavoriteDatasets' do
  context 'logged in user' do
    let!(:students) { FactoryGirl.create(:dataset_description, en_title: 'students', with_dataset: true) }
    let!(:field_description) { FactoryGirl.create(:field_description, identifier: 'name', dataset_description: students) }
    let!(:record) { students.dataset_model.create!(name: 'Filip Velky') }

    before(:each) do
      login_as(admin_user)
    end

    it 'is able to mark dataset record as favorite and see his favorite records in his profile', js: true do
      visit dataset_record_path(dataset_id: students, id: record, locale: :en)

      click_link 'add_to_favorites'

      fill_in 'note', with: 'my friend'
      click_button 'Submit'
      page.should have_link 'remove_from_favourites'

      click_link 'Favorite'

      page_should_have_content_with 'my friend', 'students', record.id.to_s
    end

    it 'user is able to remove record from favorites', js: true do
      FactoryGirl.create(:favorite, user: admin_user, dataset_description: students, record: record, note: 'check this one later')

      visit dataset_record_path(dataset_id: students, id: record, locale: :en)

      click_link 'remove_from_favourites'
      page.should have_link 'add_to_favorites'

      click_link 'Favorite'

      page_should_not_have_content_with 'check this one later', 'students'
    end
  end
end