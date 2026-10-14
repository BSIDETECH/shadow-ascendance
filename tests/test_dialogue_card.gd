extends Object

const DialogueCardScript = preload("res://scripts/ui/dialogue_card.gd")

func run_all(runner) -> void:
    await runner.process_frame # Await for standard interface compatibility if the runner expects coroutines
    print("Running DialogueCard tests...")
    test_setup_message_basic(runner)
    test_setup_message_fallback_portrait(runner)
    test_setup_message_status_styling(runner)
    test_setup_message_override_color(runner)
    test_setup_message_missing_nodes(runner)
    test_setup_message_with_explicit_portrait(runner)
    test_setup_message_out_of_bounds_status(runner)
    print("DialogueCard tests completed.")

func test_setup_message_missing_nodes(runner) -> void:
    var card = DialogueCardScript.new()
    runner.root.add_child(card)

    # Missing nodes scenario (should not crash)
    card.setup_message("Ghost", "Invisible text")

    # If it didn't crash, we pass
    runner.record_pass("DialogueCard setup_message missing_nodes")

    # Verify root stylebox is still applied
    var stylebox = card.get_theme_stylebox("panel") as StyleBoxFlat
    runner.assert_ne(stylebox, null, "DialogueCard stylebox missing_nodes", "Stylebox override should still be applied even if children are missing")

    card.queue_free()

func test_setup_message_with_explicit_portrait(runner) -> void:
    var card = _setup_mock_card()
    runner.root.add_child(card)

    var tex = PlaceholderTexture2D.new()
    card.setup_message("Lyra", "Hello", card.Status.INFO, tex)

    runner.assert_eq(card.portrait_rect.texture, tex, "DialogueCard setup_message explicit_portrait", "Explicit portrait should be assigned")

    card.queue_free()

func test_setup_message_out_of_bounds_status(runner) -> void:
    var card = _setup_mock_card()
    runner.root.add_child(card)

    # Status bounds are clampi(status, 0, Status.INFO)
    card.setup_message("Bug", "Glitch", 999)

    runner.assert_eq(card.status_badge.text, "[RÁDIO]", "DialogueCard setup_message out_of_bounds_status", "Status badge should clamp to INFO")

    card.queue_free()

func _setup_mock_card() -> Node:
    var card = DialogueCardScript.new()

    # Mock node structure required by setup_message
    var margin = MarginContainer.new()
    margin.name = "Margin"
    card.add_child(margin)

    var hbox = HBoxContainer.new()
    hbox.name = "HBox"
    margin.add_child(hbox)

    var portrait = TextureRect.new()
    portrait.name = "Portrait"
    hbox.add_child(portrait)

    var content_vbox = VBoxContainer.new()
    content_vbox.name = "ContentVBox"
    hbox.add_child(content_vbox)

    var header_hbox = HBoxContainer.new()
    header_hbox.name = "HeaderHBox"
    content_vbox.add_child(header_hbox)

    var speaker_label = Label.new()
    speaker_label.name = "SpeakerLabel"
    header_hbox.add_child(speaker_label)

    var status_badge = Label.new()
    status_badge.name = "StatusBadge"
    header_hbox.add_child(status_badge)

    var message_label = Label.new()
    message_label.name = "MessageLabel"
    content_vbox.add_child(message_label)

    # Manually assign onready vars
    card.portrait_rect = portrait
    card.speaker_label = speaker_label
    card.status_badge = status_badge
    card.message_label = message_label

    return card

func test_setup_message_basic(runner) -> void:
    var card = _setup_mock_card()
    runner.root.add_child(card)

    card.setup_message("Lyra", "Hello World")

    runner.assert_eq(card.speaker_label.text, "Lyra", "DialogueCard setup_message", "Speaker should be Lyra")
    runner.assert_eq(card.message_label.text, "Hello World", "DialogueCard setup_message", "Message should be Hello World")
    runner.assert_eq(card.status_badge.text, "[RÁDIO]", "DialogueCard setup_message", "Status badge should default to INFO ([RÁDIO])")

    card.queue_free()

func test_setup_message_fallback_portrait(runner) -> void:
    var card = _setup_mock_card()
    runner.root.add_child(card)

    card.setup_message("Maga", "Fallback test")

    runner.assert_ne(card.portrait_rect.texture, null, "DialogueCard setup_message portrait", "Fallback portrait should be assigned from existing texture")

    card.queue_free()

func test_setup_message_status_styling(runner) -> void:
    var card = _setup_mock_card()
    runner.root.add_child(card)

    card.setup_message("Paladino", "Hesitate", card.Status.HESITATE)

    runner.assert_eq(card.status_badge.text, "[HESITA]", "DialogueCard setup_message status", "Status badge should be [HESITA] for HESITATE")

    var stylebox = card.get_theme_stylebox("panel") as StyleBoxFlat
    runner.assert_ne(stylebox, null, "DialogueCard stylebox", "Stylebox override should be applied")
    if stylebox != null:
        runner.assert_eq(stylebox.bg_color, Color(0.16, 0.12, 0.03, 0.90), "DialogueCard stylebox bg_color", "Background color should match HESITATE preset")

    card.queue_free()

func test_setup_message_override_color(runner) -> void:
    var card = _setup_mock_card()
    runner.root.add_child(card)

    var custom_color = Color(1.0, 0.5, 0.5, 1.0)
    card.setup_message("Admin", "Override", card.Status.OBEY, null, custom_color)

    var stylebox = card.get_theme_stylebox("panel") as StyleBoxFlat
    runner.assert_ne(stylebox, null, "DialogueCard stylebox override", "Stylebox override should be applied")
    if stylebox != null:
        runner.assert_eq(stylebox.border_color, custom_color, "DialogueCard stylebox border_color", "Border color should match override color")

    card.queue_free()
