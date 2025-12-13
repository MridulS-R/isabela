module ApplicationHelper
  def attachment_present?(attachment)
    return false unless attachment&.attached?
    begin
      service = ActiveStorage::Blob.service
      service.respond_to?(:exist?) ? service.exist?(attachment.blob.key) : attachment.attached?
    rescue
      attachment.attached?
    end
  end
end

