function onNoteCreate(note, strumline)
{
	if (note.type == 'Hurt Note')
	{
		note.shaderNote.setArray([0xFF101010, 0xFFFF0000, 0xFF990022]);
		note.hitCausesMiss = true;
		note.mA = 0.6;
	}
}
