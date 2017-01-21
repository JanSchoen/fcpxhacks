-- LANGUAGE: Dutch
-- AUTHOR: Jan Schoen
return {
	nl = {

		--------------------------------------------------------------------------------
		-- GENERIC:
		--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- Numbers:
			--------------------------------------------------------------------------------
			one									=			"1",
			two									=			"2",
			three								=			"3",
			four								=			"4",
			five								=			"5",
			six									=			"6",
			seven								=			"7",
			eight								=			"8",
			nine								=			"9",
			ten									=			"10",

			--------------------------------------------------------------------------------
			-- Common Strings:
			--------------------------------------------------------------------------------
			button								=			"Knop",
			options								=			"Keuzes",
			open								=			"Open",
			secs								=
			{
				one								=			"sec",
				other							=			"secs",
			},
			mins								=
			{
				one								=			"min",
				other							=			"mins",
			},
			version								=			"Versie",
			unassigned							=			"Unassigned",
			enabled								=			"Enabled",
			disabled							=			"Disabled",

		--------------------------------------------------------------------------------
		-- DIALOG BOXES:
		--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- Buttons:
			--------------------------------------------------------------------------------
			ok                                  =             "OK",
			yes                                 =             "Ja",
			no                                  =             "Nee",
			done                                =             "Klaar",
			cancel                              =             "Afbreken",
			buttonContinueBatchExport     	    =             "Ga door met Batch Export",

			--------------------------------------------------------------------------------
			-- Common Error Messages:
			--------------------------------------------------------------------------------
			commonErrorMessageStart             =           "Sorry, de volgende fout is opgetreden:",
			commonErrorMessageEnd               =           "Wilt u deze fout naar Chris e-mailen, zodat hij een oplossing kan vinden?",

			--------------------------------------------------------------------------------
			-- Common Strings:
			--------------------------------------------------------------------------------
			pleaseTryAgain                      =           "Probeert u het alstublieft opnieuw",
			doYouWantToContinue                 =           "Wilt u doorgaan?",

			--------------------------------------------------------------------------------
			-- Notifications:
			--------------------------------------------------------------------------------
			hasLoaded                           =           "Is geladen",
			keyboardShortcutsUpdated            =           "Toetsenbord-shortcuts vernieuwd",
			keywordPresetsSaved                 =           "Uw keywords zijn als preset opgeslagen",
			keywordPresetsRestored              =           "Uw keywords zijn teruggezet naar preset",
			scrollingTimelineDeactivated        =           "Scrollende tijdlijn niet meer actief",
			scrollingTimelineActivated          =           "Scrollende tijdlijn is actief",
			playheadLockActivated               =           "Playhead vergrendeling is actief",
			playheadLockDeactivated             =           "Playhead vergrendeling niet meer actief",
			pleaseSelectSingleClipInTimeline    =           "Selecteer één clip in de tijdlijn.",

			--------------------------------------------------------------------------------
			-- Update Effects List:
			--------------------------------------------------------------------------------
			updateEffectsListWarning            =           "Afhankelijk van het aantal effecten dat u heeft geïnstalleerd kan dit proces enige tijd duren.\n\nWilt u alstublieft uw muis of toetsenbord niet gebruiken totdat u zeker weet dat het hele proces is uitgevoerd.",
			updateEffectsListFailed             =           "Helaas is de Effectenlijst niet succesvol vernieuwd.",
			updateEffectsListDone               =           "Effectenlijst is succesvol vernieuwd.",

			--------------------------------------------------------------------------------
			-- Update Transitions List:
			--------------------------------------------------------------------------------
			updateTransitionsListWarning        =           "Afhankelijk van het aantal transitions dat u heeft geïnstalleerd kan dit proces enige tijd duren.\n\nWilt u alstublieft uw muis of toetsenbord niet gebruiken totdat u zeker weet dat het hele proces is uitgevoerd.",
			updateTransitionsListFailed         =           "Helaas is de transitionslijst niet succesvol vernieuwd.",
			updateTransitionsListDone           =           "transitionslijst is succesvol vernieuwd.",

			--------------------------------------------------------------------------------
			-- Update Titles List:
			--------------------------------------------------------------------------------
			updateTitlesListWarning             =           "Afhankelijk van het aantal titels dat u heeft geïnstalleerd kan dit proces enige tijd duren.\n\nWilt u alstublieft uw muis of toetsenbord niet gebruiken totdat u zeker weet dat het hele proces is uitgevoerd.",
			updateTitlesListFailed              =           "Helaas is de titelslijst niet succesvol vernieuwd.",
			updateTitlesListDone                =           "Titelslijst is succesvol vernieuwd.",

			--------------------------------------------------------------------------------
			-- Update Generators List:
			--------------------------------------------------------------------------------
			updateGeneratorsListWarning         =           "Afhankelijk van het aantal generators dat u heeft geïnstalleerd kan dit proces enige tijd duren.\n\nWilt u alstublieft uw muis of toetsenbord niet gebruiken totdat u zeker weet dat het hele proces is uitgevoerd.",
			updateGeneratorsListFailed          =           "Helaas is de generatorslijst niet succesvol vernieuwd.",
			updateGeneratorsListDone            =           "Generators lijst is succesvol vernieuwd.",

			--------------------------------------------------------------------------------
			-- Assign Shortcut Errors:
			--------------------------------------------------------------------------------
			assignEffectsShortcutError          =           "De Effectenlijst is niet de allernieuwste versie \n\nUpdate alstublieft uw Effectenlijst en probeer het opnieuw ",
			assignTransitionsShortcutError      =           "De Transitionslijst is niet de allernieuwste versie \n\nUpdate alstublieft uw Transitionslijst en probeer het opnieuw.",
			assignTitlesShortcutError           =           "De Titelslijst is niet de allernieuwste versie \n\nUpdate alstublieft uw Titelslijst en probeer het opnieuw.",
			assignGeneratorsShortcutError       =           "De Generatorslijst is niet de allernieuwste versie \n\nUpdate alstublieft uw Generatorslijst en probeer het opnieuw.",

			--------------------------------------------------------------------------------
			-- Error Messages:
			--------------------------------------------------------------------------------
			wrongHammerspoonVersionError		=			"FCPX Hacks werkt alleen met Hammerspoon %{version} of  nieuwer.\n\nDownload a.u.b.de laatste versie van  Hammerspoon en probeer het opnieuw.",

			noValidFinalCutPro                  =           "FCPX Hacks kan op deze computer geen geschikte versie van Final Cut Pro vinden\n\nkijkt u alstublieft of Final Cut Pro 10.2.3, 10.3 of een hogere versie is geïnstalleerd in the hoofdmap van de Programmafolder en geen andere naam heeft gekregen dan ’Final Cut Pro'.\n\nHammerspoon wordt nu gestopt.",
			missingFiles                        =           "FCPX Hacks mist een aantal noodzakelijke files.\n\nWilt u alstublieft proberen om opnieuw de laatste versie van FCPX Hacks te downloaden van de website en volg de installatie-instructies zorgvuldig op.\n\nHammerspoon wordt nu gestopt.",

			customKeyboardShortcutsFailed       =           "Tijdens het uitlezen van uw eigen toetsenbord-shortcuts ging er iets mis\n\nAs werd niet opgeslagen, sorry, de standaard toetsenbord-shortcuts zullen nu worden gebruikt  ",

			newKeyboardShortcuts                =           "Deze laatste versie van FCPX Hacks heeft mogelijk nieuwe toetsenbord-shortcuts.\n\nOm deze shortcuts te tonen in De Final Cut Pro Commando Editor, moeten de shortcut files worden ge-updated.\n\n U moet uw beheerderswachtwoord invoeren.",
			newKeyboardShortcutsRestart         =           "Deze laatste versie van FCPX Hacks heeft mogelijk nieuwe toetsenbord-shortcuts.\n\nOm deze shortcuts te tonen in De Final Cut Pro Commando Editor, moeten de shortcut files worden ge-updated.\n\n U moet uw beheerderswachtwoord invoeren en Final Cut Pro opnieuw opstarten.",

			prowlError                          =           "De Prowl API Sleutel is niet geldig als gevolg van  de volgende fout:",

			sharedClipboardFileNotFound         =           "De Gedeelde Clipboard file kon niet worden gevonden.",
			sharedClipboardNotRead              =           "De Gedeelde Clipboard file kon niet worden gelezen.",

			restartFinalCutProFailed            =           "We waren niet in staat om Final Cut Pro te herstarten.\n\nWilt a.u.b zelf Final Cut Pro handmatig herstarten.",

			keywordEditorAlreadyOpen            =           "Deze shortcut kan alleen worden gebruikt waneer de toetsenbord Editor  open is.\n\nOpen a.u.b. de Toetsenbord Editor en probeer het opnieuw.",
			keywordShortcutsVisibleError        =           "Zorg er a.u.b. voor dat de Toetsenbord Shortcuts zichtbaar zijn voordat u deze voorziening gebruikt.",
			noKeywordPresetsError               =           "Het lijkt er op dat u tot dusver geen keyword instelling heeft opgeslagen?",
			noKeywordPresetError                =           "Het lijkt er op dat u niets heeft opgeslagen van deze keyword instelling?",

			noTransitionShortcut                =           "Er is geen Transition gekoppeld aan deze shortcut.\n\nU kunt Transitions koppelen aan shortcuts via de FCPX Hacks menu bar.",
			noEffectShortcut                    =           "Er is geen Effect gekoppeld aan deze shortcut.\n\nU kunt Effects koppelen aan shortcuts via de FCPX Hacks menu bar.",
			noTitleShortcut                     =           "Er is geen Title gekoppeld aan deze shortcut.\n\nU kunt Titles koppelen aan shortcuts via de FCPX Hacks menu bar.",
			noGeneratorShortcut                 =           "Er is geen Generator gekoppeld aan deze shortcut.\n\nU kunt Generators koppelen aan shortcuts via de FCPX Hacks menu bar.",

			touchBarError                       =           "Touch Bar ondersteuning  vereist macOS 10.12.1 (Build 16B2657) of hoger.\n\nUpdate a.u.b. macOS en probeer het opnieuw.",

			item								=
			{
				one								=			"item",
				other							=			"items"
			},

			batchExportDestinationsNotFound		=	"We kunnen de lijst met gedeelde lokaties niet vinden.",
			batchExportNoDestination		=	"Blijkbaar heeft u geen standaard lokatie ingesteld.\n\nU kunt een standaardlokatie instellen door naar ‘Preferences’ te gaan, klik op de 'Destinations' tab, klik dan met de rechtermuisknop ingedrukt op de te kiezen lokatie en klik op ‘Make Default’.\n\nU kunt een Batch Export Lokatie preset instellen via de FCP Hacks menubar.",
			batchExportEnableBrowser		=	"Zorg er a.u.b. voor dat de browser is ingeschakeld vóór het  exporteren.",
			batchExportCheckPath				=			"Final Cut Pro zal de %{count}selected %{item} exporteren naar de volgende lokatie:\n\n\t%{path}\n\nen gebruik maken van de volgende preset:\n\n\t%{preset}\n\nAls de preset de export toevoegt aan een iTunes Playlist, zal de bestemmingsfolder worden genegeerd. %{replace}\n\nU kunt deze instellingen veranderen via de FCPX Hacks Menubar Preferences.\n\nOnderbreek a.u.b.Final Cut Pro niet nadat u de 'Continue' knop heeft ingedrukt, dit kan het automatiseringproces afbreken.",
			batchExportCheckPathSidebar			=			"Final Cut Pro zal alle items in de geselecteerde mappen exporteren naar de volgende lokatie:\n\n\t%{path}\n\ngebruik makend van de volgende preset:\n\n\t%{preset}\n\nAls de preset de export toevoegt aan een iTunes Playlist, zal de bestemmingsfolder worden genegeerd. %{replace}\n\nU kunt deze instellingen veranderen via de FCPX Hacks Menubar Preferences.\n\nOnderbreek a.u.b.Final Cut Pro niet nadat u de 'Continue' knop heeft ingedrukt, dit kan het automatiseringproces afbreken.",
			batchExportReplaceYes				=			"Exports met dezelfde filenamen worden vervangen.",
			batchExportReplaceNo				=			"Exports met dezelfde filenamen worden toegevoegd.",
			batchExportNoClipsSelected			="Zorg er a.u.b. voor dat tenminste 1 clip voor export is geselecteerd.",
			batchExportComplete				="Batch Export is nu compleet. De geselecteerde clips zijn toegevoegd aan uw render wachtrij.",

			activeCommandSetError               =           "Er ging iets mis tijdens het uitlezen van de Huidige Command Set.",
			failedToWriteToPreferences          =           "Het lukte niet om data weg te schrijven naar de Final Cut Pro Preferences file.",
			failedToReadFCPPreferences          =           "Het lukte niet om de Final Cut Pro Preferences uit te lezen",
			failedToChangeLanguage              =           "Het lukte niet om de taalversie van Final Cut Pro' te veranderen.",
			failedToRestart                     =           "Het lukte niet om Final Cut Pro te herstarten. U moet Final Cut Pro handmatig opnieuw herstarten.",

			backupIntervalFail                  =           "Het lukte niet om de Backup Interval weg te schrijven naar de Final Cut Pro Preferences file.",

			voiceCommandsError 					= 			"Gesproken commando's kon niet worden geactiveerd.\n\nprobeert u het a.u.b. opnieuw.",

			--------------------------------------------------------------------------------
			-- Yes/No Dialog Boxes:
			--------------------------------------------------------------------------------
			changeFinalCutProLanguage           =           "Om de Taalversie van FCP X te veranderen moet FCP opnieuw opgestart worden.",
			changeBackupIntervalMessage         =           "Om de Backup Interval van FCP X te veranderen moet FCP opnieuw opgestart worden.",
			changeSmartCollectionsLabel         =           "Om het Smart Collections Label van FCP X te veranderen moet FCP opnieuw opgestart worden..",

			hacksShortcutsRestart               =           "Hacks Shortcuts in Final Cut Pro Heeft uw beheerderspaswoord nodig en om effectief te zijn moet FCP ook opnieuw worden opgestart.",
			hacksShortcutAdminPassword          =           "Hacks Shortcuts in Final Cut Pro Heeft uw beheerderspaswoord nodig.",

			togglingMovingMarkersRestart        =           "Om te bewegen Markers te activeren moet FCP opnieuw worden opgestart.",
			togglingBackgroundTasksRestart      =           "Om achtergrondtaken uit voeren tijdens weergave’ te activeren moet Final Cut Pro opnieuw worden opgestart.",
			togglingTimecodeOverlayRestart      =           "Om Timecode Overlays te activeren moet FCP opnieuw worden opgestart.",

			trashFCPXHacksPreferences           =           "Weet u zeker dat u de FCPX Hacks Preferences wilt verwijderen?",
			adminPasswordRequiredAndRestart     =           "Hiervoor heeft u uw beheerderswachtwoord nodig en moet Final Cut Pro opnieuw worden opgestart.",
			adminPasswordRequired               =           "Hiervoor heeft u uw beheerderswachtwoord nodig.",

			--------------------------------------------------------------------------------
			-- Textbox Dialog Boxes:
			--------------------------------------------------------------------------------
			smartCollectionsLabelTextbox        =           "Hoe wilt u uw  Smart Collections Label benoemen:",
			smartCollectionsLabelError          =           "De Smart Collections Label die u invoerde is niet geldig.\n\nGebruikt u alstublieft alleen standaard letters en cijfers.",

			changeBackupIntervalTextbox         =           "Op welke waarde (in minuten) wilt u Final Cut Pro Backup Interval zetten?",
			changeBackupIntervalError           =           "De backup interval die u heeft ingevoerd is niet geldig. Voer aub een waarde in minuten in.",

			selectDestinationPreset				=			"Selecteert u a.u.b. een bestemmingspreset:",
			selectDestinationFolder				=			"Selecteert u a.u.b. een bestemmingsfolder:",

			--------------------------------------------------------------------------------
			-- Mobile Notifications
			--------------------------------------------------------------------------------
			iMessageTextBox						=			"Voert u a.u.b. een bij iMessage geregistreerd telefoonnummer of e-mailadres in om het bericht te sturen.:",
			prowlTextbox						=			"Voer hieronder uw Prowl API key in.\n\nAls u die niet heeft kunt u gratis registreren bij prowlapp.com.",
			prowlTextboxError 					=			"De Prowl API Key die u ingevoerd heeft is niet geldig.",

			shareSuccessful 					=			"Gedeeld is gelukt\n%{info}",
			shareFailed							=			"Het delen is niet gelukt",
			shareUnknown						=			"Typ: %{type}",
			shareDetails_export					=			"Typ: Local Export\nLocation: %{result}",
			shareDetails_youtube				=			"Typ: YouTube\nLogin: %{login}\nTitle: %{title}",
			shareDetails_Vimeo					=			"Type: Vimeo\nLogin: %{login}\nTitle: %{title}",
			shareDetails_Facebook				=			"Typ: Facebook\nLogin: %{login}\nTitle: %{title}",
			shareDetails_Youku					=			"Typ: Youku\nLogin: %{login}\nTitle: %{title}",
			shareDetails_Tudou					=			"Typ: Tudou\nLogin: %{login}\nTitle: %{title}",


		--------------------------------------------------------------------------------
		-- MENUBAR:
		--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- Update:
			--------------------------------------------------------------------------------
			updateAvailable                     =           "Update Beschikbaar",

			--------------------------------------------------------------------------------
			-- Keyboard Shortcuts:
			--------------------------------------------------------------------------------
			displayKeyboardShortcuts            =           "Toon Keyboard Shortcuts",
			openCommandEditor                   =           "Open Commandos Editer",

			--------------------------------------------------------------------------------
			-- Shortcuts:
			--------------------------------------------------------------------------------
			shortcuts                           =           "Shortcuts",
			createOptimizedMedia                =           "Creëer Optimized Media",
			createMulticamOptimizedMedia        =           "Creëer Multicam Optimized Media",
			createProxyMedia                    =           "Creëer Proxy Media",
			leaveFilesInPlaceOnImport           =           "Verplaats Files niet bij Import",
			enableBackgroundRender              =           "Sta Achtergrond Rendering Toe",

			--------------------------------------------------------------------------------
			-- Automation:
			--------------------------------------------------------------------------------
			automation                          =           "Automatisering",
			assignEffectsShortcuts              =           "Stel Effects Shortcuts In",
			assignTransitionsShortcuts          =           "Stel Transitions Shortcuts In",
			assignTitlesShortcuts               =           "Stel Titles Shortcuts In",
			assignGeneratorsShortcuts           =           "Stel Generators Shortcuts In",

				--------------------------------------------------------------------------------
				-- Effects Shortcuts:
				--------------------------------------------------------------------------------
				updateEffectsList               =           "Update Effects Lijst",
				effectShortcut                  =           "Effect Shortcut",

				--------------------------------------------------------------------------------
				-- Transitions Shortcuts:
				--------------------------------------------------------------------------------
				updateTransitionsList           =           "Update Transitions Lijst",
				transitionShortcut              =           "Transition Shortcut",

				--------------------------------------------------------------------------------
				-- Titles Shortcuts:
				--------------------------------------------------------------------------------
				updateTitlesList                =           "Update Titles Lijst",
				titleShortcut                   =           "Title Shortcut",

				--------------------------------------------------------------------------------
				-- Generators Shortcuts:
				--------------------------------------------------------------------------------
				updateGeneratorsList            =           "Update Generators Lijst",
				generatorShortcut               =           "Generator Shortcut",

				--------------------------------------------------------------------------------
				-- Automation Options:
				--------------------------------------------------------------------------------
				enableScrollingTimeline         =           "Zet Scrolling Timeline Aan",
				enableTimelinePlayheadLock      =           "Zet Timeline Playhead Blokkering Aan",
				enableShortcutsDuringFullscreen =           "Zet Shortcuts Tijdens Weergave van het volledige scherm Aan",
				closeMediaImport                =           "Sluit Media Import Als Een Kaart is aangesloten",

			--------------------------------------------------------------------------------
			-- Tools:
			--------------------------------------------------------------------------------
			tools                               =           "Gereedschap",
			importSharedXMLFile                 =           "Import Gedeelde XML File",
			pasteFromClipboardHistory           =           "Plak vanuit Clipboard Historie",
			pasteFromSharedClipboard            =           "Plak vanuit Gedeelde Clipbord",
			finalCutProLanguage                 =           "Final Cut Pro Taal",
			assignHUDButtons                    =           "Stel HUD Knoppen In",

				--------------------------------------------------------------------------------
				-- Languages:
				--------------------------------------------------------------------------------
				german                          =           "Duits",
				english                         =           "Engels",
				spanish                         =           "Spaans",
				french                          =           "Frans",
				japanese                        =           "Japans",
				chineseChina                    =           "Chinees (China)",

				--------------------------------------------------------------------------------
				-- Tools Options:
				--------------------------------------------------------------------------------
				enableTouchBar                  =           "Zet TouchBar Aan",
				enableHacksHUD                  =           "Zet Hacks Scherm Aan",
				enableMobileNotifications       =           "Zet Mobiele Meldingen Aan",
				enableClipboardHistory          =           "Zet Clipboard History Aan",
				enableSharedClipboard           =           "Zet Gedeeld Clipboard Aan",
				enableXMLSharing                =           "Zet XML Deling Aan",
				enableVoiceCommands		=	    "Zet gesproken commando's aan",

		--------------------------------------------------------------------------------
    	-- Hacks:
    	--------------------------------------------------------------------------------
		hacks                                   =           "Hacks",
		advancedFeatures                        =           "Uitgebreide Functies",

			--------------------------------------------------------------------------------
			-- Advanced:
			--------------------------------------------------------------------------------
			enableHacksShortcuts                =           "Zet Hacks Shortcuts in Final Cut Pro Aan",
			enableTimecodeOverlay               =           "Zet Tijdcode in Beeld Aan",
			enableMovingMarkers                 =           "Zet Verplaats Markers Aan",
			enableRenderingDuringPlayback       =           "Zet Rendering Gedurende Playback Aan",
			changeBackupInterval                =           "Verander Backup Interval",
			changeSmartCollectionLabel          =           "Verander Smart Collections Label",

		--------------------------------------------------------------------------------
    	-- Preferences:
    	--------------------------------------------------------------------------------
		preferences                             =           "Voorkeuren",
		quit                                    =           "Stop",

			--------------------------------------------------------------------------------
			-- Preferences:
			--------------------------------------------------------------------------------
			batchExportOptions		    =		"Batch Export Opties",
			menubarOptions                      =           "Menubar Opties",
			hudOptions                          =           "HUD Opties",
			voiceCommandOptions	   	=		"Gesproken commando's Opties",
			touchBarLocation                    =           "Touch Bar Lokatie",
			highlightPlayheadColour             =           "Accentueer Playhead Kleur",
			highlightPlayheadShape              =           "Accentueer Playhead Vorm",
			highlightPlayheadTime				=			"Accentueer Playhead Tijd",
			language							=			"Taal",
			enableDebugMode                     =           "Maak Debug Modus mogelijk",
			trachFCPXHacksPreferences           =           "Verwijder FCPX Hacks Voorkeuren",
			provideFeedback                     =           "Geef Respons",
			createdBy                           =           "Gemaakt door",
			scriptVersion                       =           "Script Versie",

			--------------------------------------------------------------------------------
			-- Notification Platform:
			--------------------------------------------------------------------------------
			iMessage							=			"iMessage",
			prowl								=			"Prowl",

			--------------------------------------------------------------------------------
			-- Batch Export Options:
			--------------------------------------------------------------------------------
			setDestinationPreset	 			=			"Stel Bestemming preset in",
			setDestinationFolder				=			"Stel Bestemming Folder in",
			replaceExistingFiles				=			"Vervang bestaande files",

			--------------------------------------------------------------------------------
			-- Menubar Options:
			--------------------------------------------------------------------------------
			showShortcuts                       =           "Toon Shortcuts",
			showAutomation                      =           "Toon Automatisering",
			showTools                           =           "Toon Gereedschap",
			showHacks                           =           "Toon Hacks",
			displayProxyOriginalIcon            =           "Geef Proxy/Origineel weer als Icon",
			displayThisMenuAsIcon               =           "Geef Dit Menu weer als Icon",

			--------------------------------------------------------------------------------
			-- HUD Options:
			--------------------------------------------------------------------------------
			showInspector                       =           "Toon Inspector",
			showDropTargets                     =           "Toon Plaats Targets",
			showButtons                         =           "Toon Knoppen",

			--------------------------------------------------------------------------------
			-- Voice Command Options:
			--------------------------------------------------------------------------------
			enableAnnouncements					=			"Sta berichtgeving toe",
			enableVisualAlerts					=			"Sta visuele waarschuwingen toe",
			openDictationPreferences			=			"Open Dictatie Preferences...",

			--------------------------------------------------------------------------------
			-- Touch Bar Location:
			--------------------------------------------------------------------------------
			mouseLocation                       =           "Muis Positie",
			topCentreOfTimeline                 =           "Boven het midden van de tijdlijn",
			touchBarTipOne                      =           "TIP: druk links OPTION",
			touchBarTipTwo                      =           "key &amp; sleep om het Venster (Touch Bar) te bewegen.",

			--------------------------------------------------------------------------------
			-- Highlight Colour:
			--------------------------------------------------------------------------------
			red                                 =           "Rood",
			blue                                =           "Blauw",
			green                               =           "Groen",
			yellow                              =           "Geel",
			custom								=			"Custom",

			--------------------------------------------------------------------------------
			-- Highlight Shape:
			--------------------------------------------------------------------------------
			rectangle                           =           "Rechthoek",
			circle                              =           "Cirkel",
			diamond                             =           "Diamant",

			--------------------------------------------------------------------------------
			-- Hammerspoon Settings:
			--------------------------------------------------------------------------------
			console                             =           "Console",
			showDockIcon                        =           "Toon Dock Icon",
			showMenuIcon                        =           "Toon Menu Icon",
			launchAtStartup                     =           "Start bij Opstarten",
			checkForUpdates                     =           "Controleer op Updates",

	--------------------------------------------------------------------------------
	-- VOICE COMMANDS:
	--------------------------------------------------------------------------------
	keyboardShortcuts					=			"Keyboard Shortcuts",
	scrollingTimeline					=			"Scrolling Timeline",
	highlight							=			"Accentueer",
	reveal								=			"Toon",
	play								=			"Speel af",
	lane								=			"Strook",

	--------------------------------------------------------------------------------
	-- HACKS HUD:
	--------------------------------------------------------------------------------
	hacksHUD							=			"Hacks HUD",
	originalOptimised					=			"Origineel/Optimised",
	betterQuality						=			"Betere kwaliteit",
	betterPerformance					=			"Betere weergave",
	proxy								=			"Proxy",
	hudDropZoneText						=			"Sleep van de Browser hier naar toe",
	hudDropZoneError					=			"Ah, ik ben er niet zeker van wat u hier versleept, maar het lijkt niet op FCPXML?",
	hudButtonError						=			"Tot op dit moment is er geen actie gekoppeld aan deze knop.\n\nU kunt een functie toewijzen aan deze knop via de FCPX Hacks menubar.",
	hudXMLNameDialog					=			"Hoe wilt u deze XML file labelen?",
	hudXMLNameError						=			"Het label dat u heeft ingevoerd bevat speciale karakters die niet kunnen worden gebruikt.\n\nProbeert u het a.u.b. opnieuw.",
	hudXMLSharingDisabled				=			"XML deling is op dit moment niet ingeschakeld.\n\nZet deling via het FCPX Hacks menu aan en probeer het opnieuwand.",

	--------------------------------------------------------------------------------
	-- CONSOLE:
	--------------------------------------------------------------------------------
	highlightedItem						=			"Accentueer Item",
	removeFromList						=			"Verwijder van de lijst",
	mode								=			"Modus",
	normal								=			"Normaal",
	removeFromList						=			"Verwijder van de lijst",
	restoreToList						=			"Herstel terug naar lijst",
	displayOptions						=			"Geef  Opties weer",
	showNone							=			"Laat niets zien",
	showAll								=			"Laat alles zien",
	showAutomation						=			"Laat Automatisering zien",
	showHacks							=			"Laat Hacks zien",
	showShortcuts						=			"Laat Shortcuts zien",
	showVideoEffects					=			"Laat Video Effects zien",
	showAudioEffects					=			"Laat Audio Effects zien",
	showTransitions						=			"Laat Transitions zien",
	showTitles							=			"Laat Titles zien",
	showGenerators						=			"Laat Generators zien",
	showMenuItems						=			"Laat Menu Items zien",
	rememberLastQuery					=			"Onthoud de laatste Opdracht",
	update								=			"Update",
	effectsShortcuts					=			"Effects Shortcuts",
	transitionsShortcuts				=			"Transitions Shortcuts",
	titlesShortcuts						=			"Titles Shortcuts",
	generatorsShortcuts					=			"Generators Shortcuts",
	menuItems							=			"Menu Items",

	}
}
