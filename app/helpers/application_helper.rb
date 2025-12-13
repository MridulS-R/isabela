module ApplicationHelper
  # Checks if an ActiveStorage::Attachment's underlying blob actually exists
  # on the configured service (guards against ephemeral/local storage 404s).
  def attachment_present?(attachment)
    return false unless attachment && attachment.respond_to?(:blob) && attachment.blob.present?
    begin
      service = ActiveStorage::Blob.service
      return true unless service.respond_to?(:exist?)
      service.exist?(attachment.blob.key)
    rescue
      true
    end
  end
end
