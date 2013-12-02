jQuery ->
  $addresses = $('.bitcoin-address')
  configureAddresses($addresses) if $addresses.length > 0

  $queue = $('table.queue')
  configureQueue($queue) if $queue.length > 0

  $index = $('body#index-body')
  configureIndex($index) if $index.length > 0

configureIndex = ($index) ->
  $message = $('#message')
  originalHtml = undefined

  # Make sure that only text is added into the message field
  $message.on 'change keyup paste', ->
    children = (child for child in @childNodes)
    for child in children when child.nodeName != '#text'
      @removeChild(child)
    undefined

  toggleEditing = (enabled) ->
    if enabled
      $message.attr('contenteditable', 'true')
    else
      $message.removeAttr('contenteditable')

    $('.editing-buttons').toggle(enabled)
    $('.change').toggle(!enabled)

  $index.find('.change').on 'click', ->
    originalHtml = $message.html()
    toggleEditing(true)

    range = document.createRange()
    range.setStart($message[0], 0)
    selection = window.getSelection()
    selection.removeAllRanges()
    selection.addRange(range)

    $message.focus()

    false

  $index.find('.submit').on 'click', ->
    $form = $('form')
    $form.find('input[name=message]').val($message.html())
    $form.submit()
    false

  $index.find('.nevermind').on 'click', ->
    toggleEditing(false)
    $message.html(originalHtml)
    false

configureQueue = ($queue) ->
  $time = $queue.find('tbody tr.winner td.time-remaining')
  return unless $time.length > 0

  formatTime($time[0])

  timer = ->
    value = parseFloat($time.attr('data-seconds'))
    if value > 0
      $time.attr('data-seconds', value - 1)
      formatTime($time[0])

  setInterval(timer, 1000)

formatTime = (element) ->
  seconds = element.getAttribute('data-seconds')

  minutes = Math.floor(seconds/60)
  seconds = seconds % 60

  if seconds < 10
    seconds = "0#{seconds}"

  element.textContent = "#{minutes}:#{seconds}"

configureAddresses = ($addresses) ->
  ZeroClipboard.setDefaults(moviePath: '/swfs/ZeroClipboard.swf')

  $('.bitcoin-address').on 'click', 'input', ->
    selection = window.getSelection()
    selection.removeAllRanges()

    range = document.createRange()
    range.selectNode(this)
    selection.addRange(range)

  clip = new ZeroClipboard($('.bitcoin-address .copy'))

  clip.on 'complete', ->
    $message = $('<div>').addClass('copied-message')
                         .text('Copied!')
                         .appendTo(document.body);

    $button = $(this)

    # Position the message centered above the button
    position = $button.offset();
    $message.css(
        top: position.top - $button.outerHeight() - 4,
        left: position.left +
            $button.outerWidth() / 2 -
            $message.outerWidth() / 2
    )

    # Fade out
    setTimeout( ->
      $message.fadeOut('slow', -> $message.remove())
    , 600)
