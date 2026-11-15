# frozen_string_literal: true

# PDF renderer used by `respond_with` in controllers: the record is
# serialized (same options as the former Jasper XML datasource:
# methods/include) and printed with its DocumentTemplate (Liquid HTML
# rendered by WeasyPrint).
ActionController::Renderers.add(:pdf) do |object, options|
  template = DocumentTemplate.find_active_template(options[:with])
  raise StandardError.new("Can not find template for #{options[:with].inspect}") unless template

  key = options[:key] || (object.respond_to?(:number) ? object.number : object.try(:id)).to_s
  name = options[:name] || "#{template.nature.l} - #{key}"
  printer = Printers::RecordPrinter.new(template: template, record: object, key: key, name: name,
                                        serialization: options.slice(:methods, :include, :only, :except))
  pdf = Ekylibre::DocumentManagement::DocumentGenerator.build.generate_pdf(template: template, printer: printer)

  Tempfile.create(['report', '.pdf']) do |file|
    file.binmode
    file.write(pdf)
    file.flush
    document = template.document(file.path, key, :pdf, name: name)
    if document && template.signed
      Ekylibre::DocumentManagement::SignatureManager.build.sign(document: document, user: document.creator)
    end
  end

  headers['Cache-Control'] = 'maxage=0'
  headers['Pragma'] = 'no-cache'
  send_data(pdf, filename: options[:filename] || "#{name.parameterize}.pdf", type: Mime[:pdf], disposition: 'inline')
end

module ActionController
  class Responder
    # Catches default view rendering and calls the PDF renderer
    def to_pdf
      controller.render(options.merge(pdf: resource))
    end
  end
end
