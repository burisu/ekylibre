(($ => $(document).ready(() => $('#fec-export-submit').on('click', function() {
  const id = $('#financial_year_id').val();
  const position = $('#fiscal_position').val();
  const interval = $("input[type='radio'][name='interval']:checked").val();

  const pattern = new RegExp(`\
(xml|text)_(.*)\
`);

  const [format, fiscalPosition] = Array.from(position.match(pattern).slice(1, 3));

  return location.href = `/backend/financial-years/${id}.${format}?fiscal_position=${fiscalPosition}&interval=${interval}`;
}))))(jQuery);
