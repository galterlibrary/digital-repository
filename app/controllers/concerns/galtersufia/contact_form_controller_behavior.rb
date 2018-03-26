module Galtersufia
  module ContactFormController
    extend ActiveSupport::Autoload
  end

  module ContactFormControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::ContactFormControllerBehavior

    included do
      before_action :spam?, only: [:create]
    end

    def spam?
      spam_msg = "potential spam detected for IP #{request.env['REMOTE_ADDR']}."
      time_to_comment = Time.now - Time.parse(session['antispam_timestamp'])
      if params[:contact_form][:customerDetail].present?
        logger.warn("#{spam_msg}, hidden customerDetail field populated.")
        redirect_to root_path
      elsif (time_to_comment < config.antispam_threshold)
        logger.warn(
          "#{spam_msg}. Antispam threshold not reached (took #{time_to_comment.to_i}s)."
        )
        redirect_to root_path
      end
    end
    private :spam?

    def create
      @contact_form = ContactForm.new(params[:contact_form])
      @contact_form.request = request
      # not spam and a valid form
      if @contact_form.respond_to?(:deliver_now) ? @contact_form.deliver_now : @contact_form.deliver
        flash[:notice] = 'Thank you for your message!'
        after_deliver
        redirect_to sufia.contact_path
      else
        flash.now[:error] = 'Sorry, this message was not sent successfully. '
        flash.now[:error] << @contact_form.errors.full_messages.map(&:to_s).join(",")
        render :new
      end
    rescue
      flash.now[:error] = 'Sorry, this message was not delivered.'
      render :new
    end
  end
end
