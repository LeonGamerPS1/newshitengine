function onNoteCreate(note, strumline) {
    if(note.type == 'No Animation') {
        note.doAnimation = false;
    }
}