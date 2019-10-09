package com.tadjaur.flash_sms

import java.util.Comparator
import java.util.HashMap

/**
 * Created by SHAJIB on 7/12/2017.
 */

internal class MapComparator(private val key: String, private val order: String) : Comparator<HashMap<String, String>> {

    override fun compare(first: HashMap<String, String>,
                         second: HashMap<String, String>): Int {
        // TODO: Null checking, both for maps and values
        val firstValue = first[key]
        val secondValue = second[key]
        return if (this.order.toLowerCase().contentEquals("asc")) {
            if (secondValue != null) {
                firstValue!!.compareTo(secondValue)
            }else {
                0
            }
        } else {
            if (firstValue != null) {
                secondValue!!.compareTo(firstValue)
            }else{
                0
            }
        }

    }
}
