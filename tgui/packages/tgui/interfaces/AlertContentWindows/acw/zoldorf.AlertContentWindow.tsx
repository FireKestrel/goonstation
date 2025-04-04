/**
 * @file
 * @copyright 2024
 * @author garash2k
 * @license ISC
 */
import { resource } from '../../../goonstation/cdn';
import { AlertContentWindow } from '../types';

export const acw: AlertContentWindow = {
  content: (
    <div className="traitor-tips">
      <h1 className="center">You are Zoldorf!</h1>
      <img src={resource('images/antagTips/zoldorf.png')} className="center" />

      <p>
        <b>IMPORTANT:</b> You are not an antagonist! As Zoldorf, your goal is to
        relay information between the dead and the living.
      </p>

      <p>
        <b>PASSIVE EFFECTS:</b>
        <br />- You can hear all speech and radio chat
        <br />- You may click-drag items within one tile of your booth
        <br />- Click-dragging a fortune to your booth will burn it.
      </p>

      <p>
        <b>ABILITIES:</b>
        <br />
        Tell Fortune: This allows you to mad-lib existing words in
        Zoldorf&apos;s vocabulary into a few pre-generated fortune formats. The
        number of lines scales from 1 to 3 depending on the number of souls
        collected from crew members. If you ever wish to write less lines, you
        may cancel the prompt at any time to print a fortune using only the
        line&apos;s you&apos;ve fully generated up to that point.
      </p>
      <p>
        Omen: This ability changes the color of your crystal ball. This is
        useful for answering direct questions from the crew.
      </p>
      <p>
        Medium: Activating your ghost light will allow you to hear dead-chat for
        30 seconds with a much longer cooldown. It&apos;s best advised to be
        used when you know people will be talking.
      </p>
      <p>
        Brand: Branding one of your fortunes will pass that brand onto the next
        person to read it, allowing you to observer them using Astral
        Projection.
      </p>
      <p>
        Astral Projection: Observe any branded player. Souldorfs are
        automatically branded
      </p>
      <p>Notes: Leave a note for your successors!</p>
      <p>
        Manifest: This abilitiy manifests your spirit into a silent and ominous
        form for a short time, allowing you to move around the station freely
        for that period of time.
      </p>
      <p>
        Seance: Your ultimate ability, after a short charging time, all ghosts
        and souldorfs on your screen will be manifested! Ghosty Party!
      </p>
      <p>
        Soul Jar: Visual display of partial souls stored in your booth. Once the
        jar spills over, you add one soul to your usable pool.
      </p>

      <p>
        <b>SUCCESSION:</b>
        <br />
        As you have usurped the previous Zoldorf, you are not immune to being
        usurped yourself. Other players may hand you the same contract to take
        over as a new Zoldorf! Doing so will give you a Yes/No prompt. If you
        say no, you&apos;ll have three more minutes of Zoldorfing before you are
        automatially tossed into the aether.
      </p>

      <p>
        After being usurped you will become a free-floating soul orb (Souldorf)
        which brings you closer to the dead, but with abilities of your own.
      </p>
      <p>
        For more information, consult{' '}
        <a href="https://wiki.ss13.co/index.php?search=Guide to Zoldorf">
          the wiki
        </a>
      </p>
    </div>
  ),
};
