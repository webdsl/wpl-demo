module bootstrap-icons

// https://icons.getbootstrap.com/

template iconsInclude {
  head {
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.4.0/font/bootstrap-icons.css">
  }
}

htmlwrapper {
  iAlarm       i[class="bi bi-alarm"]
  iAlarmFill   i[class="bi bi-alarm-fill"]
  iAlignBottom i[class="bi bi-align-bottom"]
  // ...
}


section test icons

page iconsTest {
  iconsInclude
  div {
    iAlarm
  }
  div {
    iAlarmFill
  }
  div {
    iAlignBottom
  }
}


access control rules

  rule page iconsTest { true }
