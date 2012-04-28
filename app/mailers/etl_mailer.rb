class EtlMailer < ActionMailer::Base
  layout 'mailer'
  default :from => 'admin@datanest.sk'

  def vvo_loading_status(records_with_error, records_with_note)
    @records_with_error, @records_with_note = records_with_error, records_with_note
    mail(:to => Datacamp::Application.config.admin_emails, :subject => "Vysledok automatickeho behu ETL.")
  end

  def notari_status
    @last_run_time = EtlConfiguration.find_by_name('notary_extraction').last_run_time || Time.now
    @updated_record_ids = Dataset::DcUpdate.where(updatable_type: 'Kernel::DsNotary').where('updated_at > ?', @last_run_time).map(&:updatable_id).uniq
    @created_record_ids = Kernel::DsNotary.where('created_at > ?', @last_run_time).map(&:_record_id)
    mail(to: Datacamp::Application.config.admin_emails, subject: "Notari download report.")
  end

  def executor_status
    @last_run_time = EtlConfiguration.find_by_name('executor_extraction').last_run_time || Time.now
    @updated_record_ids = Dataset::DcUpdate.where(updatable_type: 'Kernel::DsExecutor').where('updated_at > ?', @last_run_time).map(&:updatable_id).uniq
    @created_record_ids = Kernel::DsExecutor.where('created_at > ?', @last_run_time).map(&:_record_id)
    mail(to: Datacamp::Application.config.admin_emails, subject: "Exekutori download report.")
  end

  def lawyer_status
    @last_run_time = EtlConfiguration.find_by_name('lawyer_extraction').last_run_time || Time.now

    @lawyer_updated_record_ids = Dataset::DcUpdate.where(updatable_type: 'Kernel::DsLawyer').where('updated_at > ?', @last_run_time).map(&:updatable_id).uniq
    @lawyer_created_record_ids = Kernel::DsLawyer.where('created_at > ?', @last_run_time).map(&:_record_id)

    @associate_updated_record_ids = Dataset::DcUpdate.where(updatable_type: 'Kernel::DsLawyerAssociate').where('updated_at > ?', @last_run_time).map(&:updatable_id).uniq
    @associate_created_record_ids = Kernel::DsLawyerAssociate.where('created_at > ?', @last_run_time).map(&:_record_id)

    @partnership_updated_record_ids = Dataset::DcUpdate.where(updatable_type: 'Kernel::DsLawyerPartnership').where('updated_at > ?', @last_run_time).map(&:updatable_id).uniq
    @partnership_created_record_ids = Kernel::DsLawyerPartnership.where('created_at > ?', @last_run_time).map(&:_record_id)

    mail(to: Datacamp::Application.config.admin_emails, subject: "Pravnici download report.")
  end
end