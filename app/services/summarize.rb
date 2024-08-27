class Summarize
  def initialize(llm, text)
    @llm = llm
    @text = text
  end

  def call
    llm.summarize(text: text).completion
  end

  private

  attr_reader :llm, :text
end
