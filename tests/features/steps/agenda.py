from behave import given
from pages.agenda import AgendaPage


@given('we clear all bookmarks')
def step_impl(context):
    page = AgendaPage(context)
    page.visit()
    for proposal in page.proposals():
        proposal.bookmarked = False


@then('the agenda has {count:Int} proposals')
def step_impl(context, count):
    page = AgendaPage(context)
    page.visit()
    assert len(page.proposals()) == count