describe 'Handlebars Helpers', ->
  describe 'translate', ->
    beforeEach ->
      this.html = '{{translate "global.pagelens" }}'

    it 'internationalizes the String', ->
      template = Handlebars.compile this.html
      expect(template()).toEqual I18n.translate('global.pagelens')

