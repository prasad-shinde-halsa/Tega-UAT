trigger PreventEditOnSAPOfferId on Quote (before update) {
    PreventEditHelper.preventEdit(Trigger.new);
}