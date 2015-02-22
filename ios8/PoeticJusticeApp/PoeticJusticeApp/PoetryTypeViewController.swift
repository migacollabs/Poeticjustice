//
//  PoetryTypeViewController.swift
//  PoeticJusticeApp
//
//  Created by Larry Johnson on 2/17/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit

enum PoetryType: String {
    case Acrostic="Acrostic",
    Ballad="Ballad",
    Couplet="Couplet",
    Dirge="Dirge",
    Doggerel="Doggerel",
    Elegy="Elegy",
    Epigram="Epigram",
    Epitaph="Epitaph",
    FreeVerse="Free Verse",
    Lament="Lament",
    LightVerse="Light Verse",
    Limerick="Limerick",
    Lyric="Lyric",
    Ode="Ode",
    ProsePoem="Prose Poem",
    Quatrain="Quatrain",
    Rap="Rap",
    Refrain="Refrain",
    Sonnet="Sonnet",
    Verse="Verse",
    Unspecified="Unspecified"
    
    static let values = [Acrostic, Ballad, Couplet, Dirge, Doggerel, Elegy,
        Epigram, Epitaph, FreeVerse, Lament, LightVerse, Limerick,
        Lyric, Ode, ProsePoem, Quatrain, Rap, Refrain, Sonnet, Verse, Unspecified]
}

class Poetry {
    var poetryType : PoetryType = PoetryType.Unspecified
    var description : String = ""
    
    init(poetryType : PoetryType, desc : String) {
        self.poetryType = poetryType
        self.description = desc
    }
}

class PoetryTypeViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    private var poetryType : PoetryType = PoetryType.Unspecified
    private var poetryDefinitions : [Poetry] = []
    
    @IBOutlet var poetryTypePicker: UIPickerView!
    @IBOutlet var definitionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Poetry Types"
        
        definitionLabel.text = ""
        
        self.loadPoetryDefinitions()
        
        poetryTypePicker.delegate = self
        poetryTypePicker.dataSource = self
        
        // initialize to the first one
        var p = poetryDefinitions[0]
        definitionLabel.text = p.description
        
        // Do any additional setup after loading the view.
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.poetryDefinitions.count
    }
    
    func pickerView(pickerView: UIPickerView!, titleForRow row: Int, forComponent component: Int) -> String! {
        var p = poetryDefinitions[row]
        return p.poetryType.rawValue
    }
    
    func pickerView(pickerView: UIPickerView!, didSelectRow row: Int, inComponent component: Int) {
        var p = poetryDefinitions[row]
        definitionLabel.text = p.description
    }
    
    func loadPoetryDefinitions() {
        // TODO: mention this is from Wikipedia
        // http://en.wikipedia.org/wiki/Wikipedia:FAQ/Copyright#Can_I_reuse_Wikipedia.27s_content_somewhere_else.3F
        
        poetryDefinitions.removeAll(keepCapacity: false)
            
        poetryDefinitions.append(Poetry(poetryType: PoetryType.Acrostic, desc: "Form of writing in which the first letter, syllable or word of each line, paragraph or other recurring feature in the text spells out a word or a message."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.Ballad, desc: "Form of verse, often a narrative set to music. Ballads derive from the medieval French chanson balladée or ballade, which were originally 'dancing songs'. Ballads were particularly characteristic of the popular poetry and song of the British Isles from the later medieval period until the 19th century and used extensively across Europe and later the Americas, Australia and North Africa."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.Couplet, desc: "A pair of lines of metre in poetry. Couplets usually comprise two lines that rhyme and have the same metre. A couplet may be formal (closed) or run-on (open). In a formal (or closed) couplet, each of the two lines is end-stopped, implying that there is a grammatical pause at the end of a line of verse. In a run-on (or open) couplet, the meaning of the first line continues to the second."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.Dirge, desc: "A somber song or lament expressing mourning or grief, such as would be appropriate for performance at a funeral."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.Doggerel, desc: "Doggerel is poetry that is irregular in rhythm and in rhyme, often deliberately for burlesque or comic effect. The word is derived from the Middle English dogerel, probably a diminutive of dog."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.Elegy, desc: "A mournful, melancholic or plaintive poem, especially a funeral song or a lament for the dead."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.Epigram, desc: "A brief, interesting, memorable, and sometimes surprising or satirical statement."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.Epitaph, desc: "A short text honoring a deceased person. Strictly speaking, it refers to text that is inscribed on a tombstone or plaque, but it may also be used in a figurative sense. Some epitaphs are specified by the person themselves before their death, while others are chosen by those responsible for the burial."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.FreeVerse, desc: "An open form of poetry. It does not use consistent meter patterns, rhyme, or any other musical pattern. It thus tends to follow the rhythm of natural speech."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.Lament, desc: "A passionate expression of grief, often in music, poetry, or song form. The grief is most often born of regret, or mourning."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.LightVerse, desc: "Poetry that attempts to be humorous. Poems considered 'light' are usually brief, and can be on a frivolous or serious subject, and often feature word play, including puns, adventurous rhyme and heavy alliteration."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.Limerick, desc: "A form of poetry,[1] especially one in five-line anapestic meter with a strict rhyme scheme (AABBA), which is sometimes obscene with humorous intent. The first, second and fifth lines are usually longer than the third and fourth."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.Lyric, desc: "A form of poetry which expresses personal emotions or feelings, typically spoken in the first person."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.Ode, desc: "A type of lyrical stanza; an elaborately structured poem praising or glorifying an event or individual, describing nature intellectually as well as emotionally."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.ProsePoem, desc: "Poetry written in prose instead of using verse but preserving poetic qualities such as heightened imagery, parataxis and emotional effects."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.Quatrain, desc: "A type of stanza, or a complete poem, consisting of four lines."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.Rap, desc: "Spoken or chanted rhyming lyrics. The components of rapping include 'content', 'flow' (rhythm and rhyme), and 'delivery'. Rapping is distinct from spoken word poetry in that it is performed in time to a beat. Rapping is often associated with and a primary ingredient of hip hop music, but the origins of the phenomenon can be said to predate hip hop culture by centuries."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.Refrain, desc: "The line or lines that are repeated in music or in verse; the 'chorus' of a song."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.Sonnet, desc: "A poem of fourteen lines that follows a strict rhyme scheme and specific structure. Conventions associated with the sonnet have evolved over its history."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.Verse, desc: "A single metrical line in a poetic composition. However, verse has come to represent any division or grouping of words in a poetic composition, with groupings traditionally having been referred to as stanzas."))
        poetryDefinitions.append(Poetry(poetryType: PoetryType.Unspecified, desc: "A free for all! Anything you want to write about with no rules or structures in place."))
    }
    
    override func viewWillAppear(animated: Bool) {
            // TODO: update page based on selected poetry type
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}