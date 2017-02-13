module ACCUSchedule.View exposing (view)

import ACCUSchedule.Days as Days
import ACCUSchedule.Model as Model
import ACCUSchedule.Msg as Msg
import ACCUSchedule.Routing as Routing
import ACCUSchedule.Sessions as Sessions
import ACCUSchedule.Types as Types
import Html exposing (a, br, div, h1, Html, p, text)
import Material.Button as Button
import Material.Card as Card
import Material.Chip as Chip
import Material.Color as Color
import Material.Elevation as Elevation
import Material.Footer as Footer
import Material.Grid as Grid
import Material.Icon as Icon
import Material.Layout as Layout
import Material.Options as Options
import Material.Textfield as Textfield
import Material.Typography as Typo


proposalCardGroup : Int
proposalCardGroup =
    0


bookmarksControlGroup : Int
bookmarksControlGroup =
    1


searchFieldControlGroup : Int
searchFieldControlGroup =
    2


{-| Find a proposal based on a string representation of its id.

   This is just convenience for parsing the route.
-}
findProposal : Model.Model -> Types.ProposalId -> Maybe Types.Proposal
findProposal model id =
    (List.filter (\p -> p.id == id) model.proposals) |> List.head


roomToString : Types.Room -> String
roomToString room =
    case room of
        Types.BristolSuite ->
            "Bristol Suite"

        Types.Bristol1 ->
            "Bristol 1"

        Types.Bristol2 ->
            "Bristol 2"

        Types.Bristol3 ->
            "Bristol 3"

        Types.Empire ->
            "Empire"

        Types.GreatBritain ->
            "Great Britain"


{-| Create a display-ready string of the names of all presenters for a proposal.
-}
presenters : Types.Proposal -> String
presenters proposal =
    let
        fullName =
            \p -> p.firstName ++ " " ++ p.lastName

        presenterNames =
            List.map fullName proposal.presenters
    in
        String.join ", " presenterNames


{-| A card-view of a single proposal. This displays the title, presenters,
location, and potentially other information about a proposal, though not the
full text of the abstract. This includes a clickable icon for "starring" a
propposal.
-}
proposalCard : Model.Model -> Types.Proposal -> Html Msg.Msg
proposalCard model proposal =
    let
        room =
            roomToString proposal.room

        time =
            Sessions.toString proposal.session

        dayLink =
            Layout.link
                [ Layout.href (Routing.dayUrl proposal.day) ]
                [ text <| Days.toString proposal.day ]
    in
        Card.view
            [ Options.onClick (Msg.VisitProposal proposal)
            , Elevation.e2
            , Options.css "margin-right" "5px"
            , Options.css "margin-bottom" "5px"
            ]
            [ Card.title
                [ Color.text Color.black
                , Color.background Color.white
                ]
                ([ Card.head [] [ text proposal.title ]
                 ]
                )
            , Card.text
                [ Color.text Color.black
                , Color.background Color.white
                , Card.expand
                ]
                [ text (presenters proposal)
                , br [] []
                , dayLink
                , text <| ", " ++ time ++ ", " ++ room
                ]
            , Card.actions
                [ Card.border
                , Color.background Color.accent
                , Color.text Color.white
                , Typo.right
                ]
                [ bookmarkButton model proposal ]
            ]


flowCardView : Model.Model -> List Types.Proposal -> Html Msg.Msg
flowCardView model proposals =
    Options.div
        [ Options.css "display" "flex"
        , Options.css "flex-flow" "row wrap"
        ]
        (List.map (proposalCard model) proposals)


sessionView : Model.Model -> List Types.Proposal -> Types.Session -> List (Html Msg.Msg)
sessionView model props session =
    let
        proposals =
            List.filter (.session >> (==) session) props
    in
        case List.head proposals of
            Nothing ->
                []

            Just prop ->
                let
                    s =
                        Sessions.toString prop.session

                    d =
                        Days.toString prop.day

                    label =
                        d ++ ", " ++ s
                in
                    [ Chip.span [ Options.css "margin-bottom" "5px" ]
                        [ Chip.content []
                            [ text label ]
                        ]
                    , flowCardView model proposals
                    ]


{-| Display all proposals for a particular day.
-}
dayView : Model.Model -> List Types.Proposal -> Days.Day -> List (Html Msg.Msg)
dayView model proposals day =
    let
        props =
            List.filter (.day >> (==) day) proposals

        sview =
            sessionView model props
                >> Options.styled div
                    [ Options.css "margin-bottom" "10px" ]
    in
        List.map
            sview
            Sessions.conferenceSessions


{-| Display all "bookmarks" proposals, i.e. the users personal agenda.
-}
agendaView : Model.Model -> List (Html Msg.Msg)
agendaView model =
    let
        props =
            List.filter (\p -> List.member p.id model.bookmarks) model.proposals
    in
        List.concatMap (dayView model props) Days.conferenceDays


bookmarkButton : Model.Model -> Types.Proposal -> Html Msg.Msg
bookmarkButton model proposal =
    let
        icon =
            if List.member proposal.id model.bookmarks then
                "bookmark"
            else
                "bookmark_border"
    in
        Button.render Msg.Mdl
            [ proposalCardGroup
            , bookmarksControlGroup
            , proposal.id
            ]
            model.mdl
            [ Button.icon
            , Button.ripple
            , Options.onClick <| Msg.ToggleBookmark proposal.id
            ]
            [ Icon.i icon ]


{-| Display a single proposal. This includes all of the details of the proposal,
including the full text of the abstract.
-}
proposalView : Model.Model -> Types.Proposal -> Html Msg.Msg
proposalView model proposal =
    let
        room =
            roomToString proposal.room

        session =
            Sessions.toString proposal.session

        location =
            session ++ ", " ++ room
    in
        Options.div
            [ Options.css "display" "flex"
            , Options.css "flex-flow" "row wrap"
              -- , Options.css "justify" "center"
            , Options.css "justify-content" "flex-start"
            , Options.css "align-items" "flex-start"
            ]
            [ Options.styled p
                []
                [ proposalCard model proposal ]
            , Options.styled p
                [ Typo.body1
                , Options.css "width" "30em"
                , Options.css "margin-left" "10px"
                ]
                [ text proposal.text ]
            ]


searchView : Model.Model -> String -> Html Msg.Msg
searchView model term =
    let
        matching =
            \p -> String.contains term p.text

        proposals =
            List.filter matching model.proposals
    in
        flowCardView model proposals


notFoundView : Html Msg.Msg
notFoundView =
    div []
        [ text "view not found :("
        ]


drawerLink : String -> String -> Html Msg.Msg
drawerLink url linkText =
    Layout.link
        [ Layout.href url
        , Options.onClick <| Layout.toggleDrawer Msg.Mdl
        ]
        [ text linkText ]


dayLink : Days.Day -> Html Msg.Msg
dayLink day =
    drawerLink (Routing.dayUrl day) (Days.toString day)


agendaLink : Html Msg.Msg
agendaLink =
    drawerLink Routing.agendaUrl "Agenda"


view : Model.Model -> Html Msg.Msg
view model =
    let
        main =
            case model.location of
                Routing.Day day ->
                    dayView model model.proposals day

                Routing.Proposal id ->
                    case findProposal model id of
                        Just proposal ->
                            [ proposalView model proposal ]

                        Nothing ->
                            [ notFoundView ]

                Routing.Agenda ->
                    agendaView model

                Routing.Search term ->
                    [ searchView model term ]

                _ ->
                    [ notFoundView ]

        pageName =
            case model.location of
                Routing.Day day ->
                    Days.toString day

                Routing.Proposal id ->
                    ""

                Routing.Agenda ->
                    "Agenda"

                Routing.Search term ->
                    ""

                _ ->
                    ""

        searchString =
            case model.location of
                Routing.Search x ->
                    x

                _ ->
                    ""
    in
        div
            []
            [ Layout.render Msg.Mdl
                model.mdl
                [ Layout.fixedHeader
                ]
                { header =
                    [ Layout.row
                        [ Color.background Color.primary ]
                        [ Layout.title
                            [ Typo.title, Typo.left ]
                            [ text "ACCU 2017" ]
                        , Layout.spacer
                        , Layout.title
                            [ Typo.title ]
                            [ text pageName ]
                        , Layout.spacer
                        , Layout.title
                            [ Typo.title
                            , Options.onInput Msg.VisitSearch
                            ]
                            [ Textfield.render Msg.Mdl
                                [ searchFieldControlGroup ]
                                model.mdl
                                [ Textfield.label "Search"
                                , Textfield.floatingLabel
                                , Textfield.value searchString
                                , Textfield.expandable "search-field"
                                , Textfield.expandableIcon "search"
                                ]
                                []
                            ]
                        ]
                    ]
                , drawer =
                    [ Layout.title [] [ text "ACCU 2017" ]
                    , Layout.navigation [] <|
                        (List.map
                            dayLink
                            Days.conferenceDays
                        )
                            ++ [ drawerLink "#/agenda" "Agenda" ]
                    ]
                , tabs = ( [], [] )
                , main =
                    [ Options.styled div
                        [ Options.css "margin-left" "10px"
                        , Options.css "margin-top" "10px"
                        , Options.css "margin-bottom" "10px"
                        ]
                        main
                    , Footer.mini []
                        { left =
                            Footer.left []
                                [ Footer.logo [] [ Footer.html <| text "ACCU 2017 Schedule" ]
                                , Footer.links []
                                    [ Footer.linkItem [ Footer.href "https://conference.accu.org/site" ] [ Footer.html <| text "Conference" ]
                                    , Footer.linkItem [ Footer.href "https://github.com/abingham/accu-2017-elm-app" ] [ Footer.html <| text "Github" ]
                                    ]
                                ]
                        , right =
                            Footer.right []
                                [ Footer.html <| text "© 2017 Sixty North AS" ]
                        }
                    ]
                }
            ]
