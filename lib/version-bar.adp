<if @versions_p@ true>
  <div class="bt_navbar" style="clear: right; float: right; padding: 4px; background-color: #41329c; text-align: center;">

    <if @user_id@ ne 0>
      #bug-tracker.Your_version# <a href="@user_version_url@" class="bt_navbar" style="font-size: 100%;">@user_version_name@</a>
      <if @user_version_id@ ne @current_version_id@>
        #bug-tracker.Current_version_1#
      </if>
      <else>
        #bug-tracker.current#
      </else>
    </if>

    <else>
      #bug-tracker.Current_version_2#
    </else>

  </div>
</if>


